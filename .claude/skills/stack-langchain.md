# Skill: LangChain + Integrações LLM
# Natural Tecnologia — nt-usina
# Arquivo: .claude/skills/stack-langchain.md
#
# USO: Injetar no Coding Agent para projetos com LangChain, LLMs e RAG.
# Versão de referência: LangChain Python >= 0.2 (LCEL — LangChain Expression Language)

---

## Instalação

```bash
pip install langchain langchain-openai langchain-anthropic langchain-community
pip install langchain-chroma chromadb  # para RAG com Chroma
pip install faiss-cpu                  # alternativa ao Chroma (sem servidor)
pip install tiktoken                   # contagem de tokens OpenAI
```

---

## LLMs — configuração por provider

```python
# OpenAI
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="gpt-4o",
    temperature=0,        # 0 para respostas determinísticas
    api_key=settings.OPENAI_API_KEY,
    max_tokens=2000,
)

# Anthropic Claude
from langchain_anthropic import ChatAnthropic

llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    temperature=0,
    api_key=settings.ANTHROPIC_API_KEY,
    max_tokens=2000,
)

# Google Gemini
from langchain_google_genai import ChatGoogleGenerativeAI

llm = ChatGoogleGenerativeAI(
    model="gemini-1.5-pro",
    google_api_key=settings.GOOGLE_API_KEY,
)
```

---

## LCEL — LangChain Expression Language (padrão atual)

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser, JsonOutputParser
from langchain_core.runnables import RunnablePassthrough

# Chain simples: prompt | llm | parser
prompt = ChatPromptTemplate.from_messages([
    ("system", "Você é um assistente especializado em {dominio}."),
    ("human", "{pergunta}"),
])

chain = prompt | llm | StrOutputParser()

# Invocar
resposta = chain.invoke({
    "dominio": "direito tributário",
    "pergunta": "O que é ICMS?"
})

# Streaming
for chunk in chain.stream({"dominio": "...", "pergunta": "..."}):
    print(chunk, end="", flush=True)

# Async
resposta = await chain.ainvoke({"dominio": "...", "pergunta": "..."})
```

---

## Prompts — boas práticas

```python
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

# System prompt com papel claro
system_prompt = """Você é um assistente de atendimento da {empresa}.

REGRAS:
- Responda apenas sobre {dominio}
- Se não souber, diga que não tem essa informação
- Seja conciso e direto
- Use linguagem {tom}

CONTEXTO DO USUÁRIO:
{contexto}"""

prompt = ChatPromptTemplate.from_messages([
    ("system", system_prompt),
    MessagesPlaceholder("historico"),  # para conversas com memória
    ("human", "{pergunta}"),
])

# Output estruturado (JSON)
from langchain_core.output_parsers import JsonOutputParser
from pydantic import BaseModel

class ClassificacaoSchema(BaseModel):
    categoria: str
    confianca: float
    motivo: str

parser = JsonOutputParser(pydantic_object=ClassificacaoSchema)
chain = prompt | llm | parser
```

---

## RAG — Retrieval Augmented Generation

```python
from langchain_community.document_loaders import PyPDFLoader, TextLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_chroma import Chroma
from langchain_core.runnables import RunnablePassthrough

# 1. Carregar documentos
loader = PyPDFLoader("documento.pdf")
docs = loader.load()

# 2. Dividir em chunks
splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,   # overlap evita perder contexto nos cortes
)
chunks = splitter.split_documents(docs)

# 3. Criar embeddings e vector store
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
vectorstore = Chroma.from_documents(
    documents=chunks,
    embedding=embeddings,
    persist_directory="./chroma_db",  # persistir em disco
)

# 4. Retriever
retriever = vectorstore.as_retriever(
    search_type="similarity",
    search_kwargs={"k": 4},  # top 4 chunks mais relevantes
)

# 5. Chain RAG
def formatar_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)

prompt_rag = ChatPromptTemplate.from_messages([
    ("system", """Responda com base APENAS no contexto fornecido.
Se a resposta não estiver no contexto, diga que não tem essa informação.

CONTEXTO:
{contexto}"""),
    ("human", "{pergunta}"),
])

chain_rag = (
    {"contexto": retriever | formatar_docs, "pergunta": RunnablePassthrough()}
    | prompt_rag
    | llm
    | StrOutputParser()
)

resposta = chain_rag.invoke("Qual é a política de reembolso?")
```

---

## Memória de conversação

```python
from langchain_core.chat_history import BaseChatMessageHistory
from langchain_community.chat_message_histories import ChatMessageHistory
from langchain_core.runnables.history import RunnableWithMessageHistory

# Armazenar histórico por session_id
store = {}

def obter_historico(session_id: str) -> BaseChatMessageHistory:
    if session_id not in store:
        store[session_id] = ChatMessageHistory()
    return store[session_id]

# Adicionar histórico à chain
chain_com_memoria = RunnableWithMessageHistory(
    chain,
    obter_historico,
    input_messages_key="pergunta",
    history_messages_key="historico",
)

# Invocar com session_id
resposta = chain_com_memoria.invoke(
    {"pergunta": "Qual foi minha última pergunta?"},
    config={"configurable": {"session_id": "usuario-123"}},
)
```

---

## Agents com tools

```python
from langchain.agents import create_tool_calling_agent, AgentExecutor
from langchain_core.tools import tool

# Definir tools
@tool
def buscar_pedido(numero_pedido: str) -> str:
    """Busca informações de um pedido pelo número."""
    # Implementação real aqui
    return f"Pedido {numero_pedido}: status Enviado, previsão 2 dias."

@tool
def verificar_estoque(produto_id: str) -> dict:
    """Verifica estoque disponível de um produto."""
    return {"produto_id": produto_id, "quantidade": 10}

tools = [buscar_pedido, verificar_estoque]

# Criar agent
agent = create_tool_calling_agent(llm, tools, prompt)
executor = AgentExecutor(
    agent=agent,
    tools=tools,
    verbose=True,          # True em dev, False em prod
    max_iterations=5,      # Evitar loops infinitos
    handle_parsing_errors=True,
)

resultado = executor.invoke({"input": "Qual o status do pedido #12345?"})
```

---

## Boas práticas e custos

```
✓ Usar temperature=0 para tarefas determinísticas (classificação, extração)
✓ Usar temperature=0.7 para geração criativa (respostas conversacionais)
✓ Limitar max_tokens para evitar respostas desnecessariamente longas
✓ Cachear respostas para queries idênticas (reduz custos)
✓ Logar tokens usados para controle de custos
✓ Testar prompts com modelo menor (ex: gpt-4o-mini) antes de usar o maior
✓ Usar streaming em endpoints de chat para melhor UX

✗ Nunca enviar dados pessoais sensíveis (CPF, senhas, cartões) para a API
✗ Nunca hardcodar API keys — sempre usar variáveis de ambiente
✗ Não confiar cegamente no output do LLM — sempre validar antes de usar
✗ Evitar chains com muitas etapas sem tratamento de erro intermediário
```

---

## Armadilhas comuns

```
✗ Usar LangChain 0.1 (legado) → migrar para LCEL (0.2+)
✗ Prompt sem instrução clara de formato → output inconsistente
✗ Não tratar RateLimitError → usar retry com backoff exponencial
✗ Vectorstore sem persist → perde embeddings ao reiniciar
✗ Chunk size muito grande → contexto relevante diluído no RAG
✗ Chunk size muito pequeno → perda de contexto nos cortes
✗ Histórico ilimitado → context window excedida em conversas longas
```

### Retry com backoff (produção)

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
)
async def chamar_llm(chain, input_data):
    return await chain.ainvoke(input_data)
```
