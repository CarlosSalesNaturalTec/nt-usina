# Estrutura de Diretórios — Natural Tecnologia
# Fábrica de Software IA

## Visão Geral

```
projeto/
│
├── CLAUDE.md                          # Contexto global do projeto (lido automaticamente pelo Claude Code)
│
├── .claude/
│   ├── agents/                        # Sub-agentes especializados
│   │   ├── orquestrador.md            # Cérebro do pipeline — lê backlog e aciona agentes
│   │   ├── po.md                      # Product Owner
│   │   ├── analista-requisitos.md     # Analista de Requisitos
│   │   ├── arquiteto.md               # Arquiteto de Software
│   │   ├── po-tech-lead.md            # PO/Tech Lead (geração de backlog)
│   │   ├── git-specialist.md          # Especialista em Git
│   │   ├── coding-agent.md            # Agente de Codificação
│   │   ├── testing-agent.md           # Agente de Testes
│   │   └── deploy-agent.md            # Agente de Deploy
│   │
│   ├── skills/                        # Conhecimento especializado injetável
│   │   ├── boas-praticas.md           # SOLID, Design Patterns, Clean Code
│   │   ├── stack-laravel-vue.md       # Laravel + Vue.js + PostgreSQL
│   │   ├── stack-gcp.md               # Google Cloud Platform
│   │   ├── stack-python.md            # Python + FastAPI
│   │   ├── stack-baileys.md           # WhiskeySockets Baileys (WhatsApp)
│   │   └── stack-langchain.md         # LangChain + LLM integrations
│   │
│   └── commands/                      # Slash commands do pipeline
│       ├── fabricar-software.md       # /fabricar-software — entry point do pipeline completo
│       ├── fabricar-tmux.md           # /fabricar-tmux — inicia sessão TMux da Natural Tecnologia
│       ├── po-processar-demanda.md    # /po-processar-demanda
│       ├── gerar-requirements.md      # /gerar-requirements
│       ├── gerar-arquitetura.md       # /gerar-arquitetura
│       ├── gerar-backlog.md           # /gerar-backlog
│       ├── feature-desenvolver.md     # /feature-desenvolver
│       ├── feature-ajustar.md         # /feature-ajustar
│       ├── versionamento-newBranch.md # /versionamento-newBranch
│       ├── versionamento-branch-push.md # /versionamento-branch-push
│       ├── testar-feature.md          # /testar-feature
│       ├── aprovar.md                 # /aprovar — modo validacao: aprova etapa atual
│       ├── reprovar.md                # /reprovar <motivo> — modo validacao: reprova e re-executa
│       ├── set-modo.md                # /set-modo <validacao|autonomo>
│       └── deploy.md                  # /deploy
│
├── scripts/
│   └── Start-Usina.ps1                # Script PowerShell que abre Windows Terminal com 4 painéis
│
├── docs/                              # Artefatos de planejamento (gerados pelos agentes)
│   ├── demanda/
│   │   └── demanda-cliente.md         # Input: demanda bruta do cliente
│   ├── user-stories.md                # Output do agente PO
│   ├── requirements.md                # Output do agente Analista de Requisitos
│   ├── architecture.md                # Output do agente Arquiteto
│   ├── pipeline.log                   # Log contínuo de execução (modo autonomo)
│   ├── bugs/                          # Relatórios de bugs (gerados pelo Testing Agent)
│   │   └── bug-YYYYMMDD-NNN.md
│   └── testes/                        # Planos e relatórios de teste
│       └── plano-FEATURE_ID.md
│
├── backlog/
│   ├── indice.json                    # Índice central com status de todas as features
│   └── grupo-NNN-NOME.json            # Detalhamento por grupo funcional
│
└── [código-fonte do projeto]          # Estrutura definida pelo Arquiteto por projeto
```

---

## Convenção de Status do Backlog

Cada item do `indice.json` possui um campo `status` com os seguintes valores possíveis:

| Status | Significado |
|---|---|
| `nao_iniciada` | Aguardando ser selecionada pelo Orquestrador |
| `em_desenvolvimento` | Branch criada, Coding Agent em execução |
| `desenvolvimento_concluido` | Código implementado, aguardando testes |
| `em_testes` | Testing Agent em execução |
| `concluida` | Aprovada em testes, PR merged em main |
| `em_recuperacao` | Item interrompido por falha; Orquestrador avalia retomada ou reset |
| `bloqueada` | Dependência não resolvida ou erro crítico que exige intervenção humana |

---

## Fluxo de Dados entre Artefatos

```
docs/demanda/demanda-cliente.md
        │
        ▼ (agente: po)
docs/user-stories.md  ──────────────────── [modo validacao: aguarda /aprovar]
        │
        ▼ (agente: analista-requisitos)
docs/requirements.md  ──────────────────── [modo validacao: aguarda /aprovar]
        │
        ▼ (agente: arquiteto)
docs/architecture.md ───────────────────── [modo validacao: aguarda /aprovar]
        │
        └──────────────────► CLAUDE.md (stack e estrutura atualizados)
        │
        ▼ (agente: po-tech-lead)
backlog/indice.json + backlog/grupo-*.json  [modo validacao: aguarda /aprovar]
        │
        ▼ (orquestrador — loop contínuo)
┌───────────────────────────────────────────────────┐
│  BOOTSTRAP: verifica itens em_recuperacao         │
│  → branch existe? retoma : reseta p/ nao_iniciada │
└──────────────┬────────────────────────────────────┘
               │
               ▼
        ├── git-specialist → cria branch
        ├── coding-agent   → implementa (chain-of-thought + skills)
        ├── git-specialist → commit + push
        └── testing-agent  → testa  ────────── [modo validacao: aguarda /aprovar]
                │
                ├── aprovado  → status "concluida" → próxima feature
                └── reprovado → cria docs/bugs/bug-*.md
                                → status "em_desenvolvimento"
                                → volta ao coding-agent
                                        │
                                        ▼ (quando todas concluídas)
                                deploy-agent → deploy para GCP
                                             [modo validacao: aguarda /aprovar]
```

---

## Convenção de Nomenclatura de Branches (GitHub Flow)

```
feature/<grupo>-<id>-<descricao-curta>

Exemplos:
  feature/auth-001-login-jwt
  feature/dashboard-003-relatorio-mensal
  feature/api-007-endpoint-usuarios
```

---

## Sessão TMux — Natural Tecnologia

O script `scripts/tmux-fabrica.sh` monta automaticamente o ambiente de monitoramento:

```
┌─────────────────────────┬──────────────────────┐
│  PAINEL 1               │  PAINEL 2            │
│  Claude Code CLI        │  Backlog Monitor     │
│  (orquestrador ativo)   │  watch -n2 cat       │
│                         │  backlog/indice.json │
├─────────────────────────┼──────────────────────┤
│  PAINEL 3               │  PAINEL 4            │
│  Git log                │  Logs da aplicação   │
│  git log --oneline      │  tail -f do projeto  │
└─────────────────────────┴──────────────────────┘
```

Iniciar com: `.\scripts\Start-Usina.ps1` (PowerShell) ou `/fabricar-tmux`

---

## Notas de Operação

- O arquivo `CLAUDE.md` na raiz é **lido automaticamente** pelo Claude Code em toda sessão. Deve conter o contexto técnico atual do projeto.
- Os agentes em `.claude/agents/` são invocados pelo Orquestrador via `Task()`. Cada agente tem acesso apenas ao conjunto de ferramentas definido em seu próprio arquivo.
- As Skills em `.claude/skills/` **não são agentes** — são arquivos de contexto referenciados com `@` nos prompts dos agentes que precisam desse conhecimento.
- O `backlog/indice.json` é o **estado central** do pipeline. Toda decisão do Orquestrador parte da leitura deste arquivo.
- O campo `operacao.modo` no `CLAUDE.md` controla se o pipeline pausa para validação humana (`validacao`) ou roda de forma contínua (`autonomo`).
- O arquivo `docs/pipeline.log` registra todas as ações do Orquestrador em modo `autonomo`, permitindo auditoria posterior.

*Natural Tecnologia — Fábrica de Software IA*
