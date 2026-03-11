#!/bin/bash

CONTAINERS=(
  open-webui
  chromadb
  docling-service
  ollama
)

for C in "${CONTAINERS[@]}"; do
  if docker ps -a --format '{{.Names}}' | grep -q "^$C$"; then
    echo "Removendo container: $C"
    docker rm -f "$C"
  else
    echo "Container não existe: $C"
  fi
done
