# Laboratório: Retrieval-Augmented Generation (RAG)

Este laboratório tem como objetivo **construir um ambiente local de RAG
(Retrieval-Augmented Generation)** utilizando ferramentas modernas do
ecossistema de IA generativa.

Ao final do laboratório, os alunos terão um sistema funcional capaz de:

-   Indexar documentos
-   Recuperar trechos relevantes
-   Utilizar modelos de linguagem para responder perguntas com base
    nesses documentos

A stack utilizada inclui:

-   Ollama -- gerenciamento de modelos locais (LLMs e embeddings)
-   Open WebUI -- interface gráfica para interação com LLMs
-   ChromaDB -- banco de dados vetorial
-   Docling -- extração de conteúdo de documentos
-   Modelos hospedados no Hugging Face

------------------------------------------------------------------------

# Estrutura da Aula

## 1. Apresentação Teórica

A aula começa com uma apresentação conceitual sobre **RAG
(Retrieval-Augmented Generation)** abordando:

-   Limitações de LLMs sem contexto
-   Conceito de recuperação semântica
-   Embeddings vetoriais
-   Bancos vetoriais
-   Pipeline RAG
-   Estratégias de re-ranking

------------------------------------------------------------------------

# 2. Laboratório

O laboratório consiste em montar **uma stack completa de RAG rodando
localmente**.

Arquitetura:

    Usuário
       │
       ▼
    Open WebUI
       │
       ├── Ollama (LLM + Embeddings + Reranker)
       │
       ├── ChromaDB (Vector Database)
       │
       └── Docling (Extração de conteúdo)

------------------------------------------------------------------------

# 2.1 Pré-requisitos

Instale previamente:

-   Git
-   Docker
-   VSCode (usado como terminal)

------------------------------------------------------------------------

# 2.2 Clonando o Repositório

Clone o repositório da disciplina:

``` bash
git clone https://github.com/marcelopita/ia_generativa_idp.git
```

O diretório clonado será a **raiz dos laboratórios da disciplina**.

Neste laboratório utilizaremos o diretório:

    2-rag

------------------------------------------------------------------------

# 2.3 Instalando Ollama (Bare Metal)

O **Ollama será instalado diretamente no host**, permitindo uso completo
da GPU.

Isso é especialmente importante para:

-   GPUs NVIDIA
-   Chips Apple Silicon que não suportam GPU em containers
    Docker.

Instale com:

``` bash
curl -fsSL https://ollama.com/install.sh | sh
```

------------------------------------------------------------------------

## Baixando os modelos

``` bash
ollama pull qwen3-embedding:0.6b
ollama pull llama3.2:3b
```

### Modelos utilizados

| Modelo                | Tipo            | Função no RAG                              | Parâmetros | Dimensão |
|----------------------|-----------------|---------------------------------------------|-----------|----------|
| `qwen3-embedding:0.6b` | Embedding Model | Converte textos em vetores para busca semântica | 600M      | 1024     |
| `llama3.2:3b`         | Language Model  | Gera respostas a partir do contexto recuperado | 3B        | —        |

## Variáveis importantes do Ollama

``` bash
export OLLAMA_NUM_PARALLEL=4
export OLLAMA_MAX_LOADED_MODELS=2
```

Inicie o servidor:

``` bash
ollama serve
```

------------------------------------------------------------------------

# 2.4 Subindo o restante da stack com Docker

Entre no diretório:

    2-rag

Execute:

``` bash
docker compose up -d
```

Saída esperada:

    [+] up 4/4
    ✔ Network 2-rag_default     Created
    ✔ Container docling-service Started
    ✔ Container chromadb        Started
    ✔ Container open-webui      Started

Para parar os serviços:

``` bash
docker compose down
```

------------------------------------------------------------------------

# 2.5 Adicionando modelos do Hugging Face no Open WebUI

Acesse o painel administrativo:

    Usuário → Painel do Admin → Configurações → Conexões → API OpenAI

Adicionar nova conexão:

    URL Base da API:
    https://router.huggingface.co/v1

    Chave da API:
    Token Hugging Face

------------------------------------------------------------------------

# 2.6 Configurando Docling no Open WebUI

    Usuário → Painel do Admin → Configurações → Documentos

Selecionar **Docling** como mecanismo de extração.

Configuração:

``` json
{
  "pipeline": "standard",
  "ocr": false,
  "table_structure": false,
  "do_layout_analysis": false,
  "pdf_dpi": 150,
  "num_workers": 4,
  "max_pages": 200
}
```

------------------------------------------------------------------------

# 2.7 Configurando Chunking

    Usuário → Painel do Admin → Configurações → Documentos

Parâmetros:

    Tamanho de chunk: 800
    Sobreposição: 150

------------------------------------------------------------------------

# 2.8 Configurando Embeddings

    Usuário → Painel do Admin → Configurações → Documentos

Modelo:

    qwen3-embedding:0.6b

------------------------------------------------------------------------

# 2.9 Configurando Recuperação

    Usuário → Painel do Admin → Configurações → Documentos → Re-ranking

Parâmetros:

    Pesquisa híbrida: ativada
    Enriquecer texto da pesquisa: ativado
    Motor de reclassificação: Padrão (SentenceTransformers)
    Top K: 30
    Top K reclassificado: 5

------------------------------------------------------------------------

# 2.10 Configurando o Prompt RAG

    Usuário → Painel do Admin → Configurações → Documentos → Modelo RAG

Prompt:

    ### Tarefa
    
    Responda à pergunta do usuário com base **exclusiva** no contexto fornecido.
    
    ---
    
    ### Regras
    
    * Use o contexto como fonte principal. Não priorize conhecimento externo.
    * Se a resposta **não estiver no contexto**, diga explicitamente: "A resposta não está no contexto fornecido."
    * Se usar conhecimento externo, sinalize claramente que está fora do contexto.
    * Não invente informações nem preencha lacunas com suposições.
    * Se o contexto for insuficiente, incompleto ou confuso, informe isso.
    * Se a pergunta for ambígua, peça esclarecimento antes de responder.
    * Parafraseie -- não copie trechos longos.
    
    ---
    
    ### Citações
    
    * Inclua citações imediatamente após cada afirmação suportada pelo contexto.
    * Não use tags XML na resposta final.
    
    ---
    
    ### Saída
    
    Resposta direta, objetiva e sem rodeios, baseada no contexto abaixo:
    
    <context>
    {{CONTEXT}}
    </context>

------------------------------------------------------------------------

# 2.11 Indexando a Base de Conhecimento

No Open WebUI:

    Workspace → Conhecimento → Novo Conhecimento

Configurar:

    Nome: PL 2338/2023
    Objetivo: Legislação da IA no Brasil

Adicionar documentos:

    Adicionar conteúdo → Carregar arquivos

Selecionar arquivos do diretório:

    docs_rag

------------------------------------------------------------------------

# 2.12 Perguntas de Teste

## Teste 1 -- Sem base de conhecimento

Pergunte no chat:

    Qual é o objetivo do PL 2338/2023?

------------------------------------------------------------------------

## Teste 2 -- Com base de conhecimento

Abra um chat **com a base selecionada**.

### Pergunta A

    Qual é o objetivo do PL 2338/2023?

Resposta esperada:

-   Regulação da IA
-   Proteção de direitos fundamentais
-   Promoção de inovação

------------------------------------------------------------------------

### Pergunta B

    Quais são as categorias de risco de sistemas de IA previstas no projeto?

Resposta esperada:

-   risco inaceitável (ou excessivo)
-   alto risco
-   risco mínimo (ou limitado)

------------------------------------------------------------------------

### Pergunta C

    O que caracteriza um sistema de IA de alto risco?

Resposta esperada:

Um sistema de IA é considerado **de alto risco** quando seu uso pode
afetar:

-   direitos fundamentais
-   segurança
-   acesso a serviços essenciais

especialmente em **contextos decisórios relevantes ou setores
sensíveis**.

------------------------------------------------------------------------

### Pergunta D

    Quem será a autoridade reguladora da IA segundo o projeto?

Resposta esperada:

O projeto propõe a criação de um **Sistema Nacional de Regulação e
Governança de Inteligência Artificial**, em vez de definir uma
autoridade única já existente.

------------------------------------------------------------------------

### Pergunta E

    Quais são as penalidades (mudar para "sanções" em seguida) previstas?

Resposta esperada:

-   Advertência
-   Multa simples
-   Multa diária
-   Publicização da infração
-   Bloqueio do sistema de IA
-   Proibição parcial ou total do sistema

------------------------------------------------------------------------

# Resultado Esperado

Ao final do laboratório, o aluno terá:

-   Um **ambiente RAG completo rodando localmente**
-   Pipeline de **extração → chunking → embeddings → busca → re-ranking
    → geração**
-   Capacidade de **consultar documentos com LLMs**

