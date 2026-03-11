#!/usr/bin/env bash
set -euo pipefail

############################################
# Config
############################################

NETWORK="rag-network"

VOLUMES=(
  open-webui
  chromadb_data
  docling_cache
)

CONTAINERS=(
  chromadb
  docling-service
  open-webui
)

OLLAMA_MODELS=(
  nomic-embed-text
  llama3.2:1b
  qwen3-embedding:0.6b
)

############################################
# Utils
############################################

log() {
  echo
  echo "==> $1"
}

wait_for_port() {
  local host=$1
  local port=$2
  local name=$3

  echo -n "Aguardando $name ($host:$port) "

  until nc -z "$host" "$port" >/dev/null 2>&1; do
    echo -n "."
    sleep 2
  done

  echo " OK"
}

ensure_network() {
  if ! docker network inspect "$NETWORK" >/dev/null 2>&1; then
    log "Criando rede Docker: $NETWORK"
    docker network create "$NETWORK" >/dev/null
  else
    log "Rede já existe: $NETWORK"
  fi
}

ensure_volumes() {
  log "Verificando volumes Docker"

  for v in "${VOLUMES[@]}"; do
    if ! docker volume inspect "$v" >/dev/null 2>&1; then
      echo "Criando volume $v"
      docker volume create "$v" >/dev/null
    else
      echo "Volume já existe: $v"
    fi
  done
}

cleanup_containers() {
  log "Removendo containers antigos (se existirem)"

  for c in "${CONTAINERS[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${c}$"; then
      echo "Removendo $c"
      docker rm -f "$c" >/dev/null
    fi
  done
}

ensure_ollama() {
  log "Verificando Ollama"

  if ! command -v ollama >/dev/null 2>&1; then
    echo "Instalando Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
  else
    echo "Ollama já instalado"
  fi

  if ! curl -sf http://localhost:11434 >/dev/null 2>&1; then
    echo "Iniciando serviço Ollama"
    nohup ollama serve >/dev/null 2>&1 &
  fi

  wait_for_port localhost 11434 "Ollama"
}

ensure_models() {
  log "Verificando modelos Ollama"

  for m in "${OLLAMA_MODELS[@]}"; do
    if ! ollama list | awk '{print $1}' | grep -q "^${m}$"; then
      echo "Baixando modelo: $m"
      ollama pull "$m"
    else
      echo "Modelo já disponível: $m"
    fi
  done
}

start_chroma() {
  log "Subindo ChromaDB"

  docker run -d \
    --name chromadb \
    --network "$NETWORK" \
    -p 8000:8000 \
    -v chromadb_data:/chroma/chroma \
    --restart unless-stopped \
    chromadb/chroma >/dev/null

  wait_for_port localhost 8000 "ChromaDB"
}

start_docling() {
  log "Subindo Docling"

  docker run -d \
    --name docling-service \
    --network "$NETWORK" \
    -p 5001:5001 \
    -e HF_TOKEN="${HF_TOKEN:-}" \
    -v docling_cache:/root/.cache/huggingface \
    --restart unless-stopped \
    ghcr.io/docling-project/docling-serve-cpu:latest >/dev/null

  wait_for_port localhost 5001 "Docling"
}

start_webui() {
  log "Subindo Open WebUI"

  docker run -d \
    --name open-webui \
    --network "$NETWORK" \
    -p 3000:8080 \
    --add-host=host.docker.internal:host-gateway \
    -v open-webui:/app/data \
    -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
    -e VECTOR_DB=chroma \
    -e CHROMA_HTTP_HOST=chromadb \
    -e CHROMA_HTTP_PORT=8000 \
    -e RAG_EMBEDDING_ENGINE=ollama \
    -e RAG_EMBEDDING_MODEL=nomic-embed-text \
    -e WEBUI_TIMEOUT=300 \
    --restart unless-stopped \
    ghcr.io/open-webui/open-webui:main >/dev/null

  wait_for_port localhost 3000 "Open WebUI"
}

############################################
# Main
############################################

echo
echo "======================================"
echo "Bootstrap Local RAG Stack"
echo "======================================"

ensure_network
ensure_volumes
cleanup_containers
ensure_ollama
ensure_models

start_chroma
start_docling
start_webui

echo
echo "======================================"
echo "Stack pronta"
echo
echo "Open WebUI: http://localhost:3000"
echo "ChromaDB:   http://localhost:8000"
echo "Docling:    http://localhost:5001"
echo "Ollama:     http://localhost:11434"
echo "======================================"
