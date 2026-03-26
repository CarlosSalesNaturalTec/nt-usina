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

| Status | Significado |
|---|---|
| `nao_iniciada` | Aguardando ser selecionada pelo Orquestrador |
| `em_desenvolvimento` | Branch criada, Coding Agent em execução |
| `desenvolvimento_concluido` | Código implementado, aguardando Testing Agent |
| `em_testes` | Testing Agent em execução |
| `concluida` | Aprovada em testes, PR merged em main |
| `em_recuperacao` | Interrompida; Orquestrador avalia retomada ou reset para `nao_iniciada` |
| `bloqueada` | Erro crítico que exige intervenção humana |

---

## Fluxo de Dados entre Artefatos

```
docs\demanda\demanda-cliente.md
        │
        ▼ (agente: po)
docs\user-stories.md  ──────────────────── [modo validacao: /aprovar]
        │
        ▼ (agente: analista-requisitos)
docs\requirements.md  ──────────────────── [modo validacao: /aprovar]
        │
        ▼ (agente: arquiteto)
docs\architecture.md + CLAUDE.md atualizado [modo validacao: /aprovar]
        │
        ▼ (agente: po-tech-lead)
backlog\indice.json + backlog\grupo-*.json  [modo validacao: /aprovar]
        │
        ▼ ORQUESTRADOR — loop sequencial (stateless por iteração)
        │
        ├─ BOOTSTRAP: verifica feature_atual em indice.json → retoma ou reseta
        │
        ├─ Seleciona próxima feature com status "nao_iniciada"
        │
        ├── Cria branch: git checkout -b feature/<grupo>-<id>-<descricao>
        │
        ├── Task(coding-agent)
        │     Recebe: {feature_id, trecho_arquitetura, skills}
        │     Produz: código em disco
        │     Retorna: {status, resumo_curto}
        │
        ├── git commit + push
        │
        ├── Task(testing-agent)               [modo validacao: /aprovar]
        │     Recebe: {feature_id, criterios_aceite}
        │     Produz: relatório em docs\testes\
        │     Retorna: {status: aprovado|reprovado, resumo_curto}
        │
        ├── APROVADO  → status "concluida" → PR → próxima feature
        └── REPROVADO → cria docs\bugs\bug-*.md
                      → Task(coding-agent, modo: "corrigir")
                      → repete ciclo de testes
                                │
                                ▼ (todas as features concluídas)
                        Task(deploy-agent)   [modo validacao: /aprovar]
```

---

## Convenção de Nomenclatura de Branches (GitHub Flow)

```
feature/<grupo>-<id>-<descricao-curta>

Exemplos:
  feature/auth-001-login-jwt
  feature/api-003-endpoint-usuarios
  feature/dashboard-005-relatorio-mensal
```

---

## Sessão Windows Terminal — Natural Tecnologia

O script `scripts\Start-Usina.ps1` monta automaticamente o ambiente:

```
┌─────────────────────────┬──────────────────────┐
│  PAINEL 1               │  PAINEL 2            │
│  Claude Code CLI        │  Pipeline Monitor    │
│  (orquestrador ativo)   │  backlog + workers   │
│                         │  ativos em tempo real│
├─────────────────────────┼──────────────────────┤
│  PAINEL 3               │  PAINEL 4            │
│  Git log --graph         │  Log da aplicação    │
└─────────────────────────┴──────────────────────┘
```

Iniciar com: `.\scripts\Start-Usina.ps1` ou `/fabricar-tmux`

---

## Notas de Operação

- `CLAUDE.md` é lido automaticamente pelo Claude Code em toda sessão
- Agentes em `.claude/agents/` são invocados via `Task()` pelo Orquestrador
- Skills em `.claude/skills/` são contexto injetável — não são agentes
- `backlog\indice.json` é o estado central; `feature_atual` rastreia a feature em execução
- `docs\pipeline.log` registra todas as ações em modo `autonomo`

*Natural Tecnologia — Fábrica de Software IA*
