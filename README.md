# nt-usina — Fábrica de Software IA

**Natural Tecnologia** — Framework de desenvolvimento de software orquestrado por agentes de IA,
construído sobre o ecossistema Claude Code.

---

## O que é

A **nt-usina** é um template de fábrica de software que automatiza o ciclo completo de
desenvolvimento: da demanda do cliente ao deploy em produção, usando agentes de IA especializados
para cada etapa do pipeline.

```
Demanda do cliente
      ↓
  [PO Agent]        → user stories
      ↓
  [Analista]        → requisitos técnicos
      ↓
  [Arquiteto]       → arquitetura + stack
      ↓
  [PO/Tech Lead]    → backlog granular
      ↓
  [Orquestrador]    → loop de features:
    ├─ [Git]          criar branch
    ├─ [Coding]       implementar
    ├─ [Git]          commit + PR
    └─ [Testing]      validar
      ↓
  [Deploy Agent]    → produção
```

---

## Pré-requisitos

| Ferramenta | Versão mínima | Instalação |
|---|---|---|
| [Claude Code CLI](https://claude.ai/code) | Última | `npm install -g @anthropic-ai/claude-code` |
| [GitHub CLI](https://cli.github.com/) | 2.x | `winget install GitHub.cli` |
| [Git](https://git-scm.com/) | 2.x | `winget install Git.Git` |
| [PowerShell](https://github.com/PowerShell/PowerShell) | 7+ | Já incluído no Windows 11 |
| [Windows Terminal](https://aka.ms/terminal) | 1.x | Microsoft Store |

---

## Configuração inicial (uma vez por máquina)

Os agentes, comandos e skills da fábrica vivem no contexto **global do usuário** Claude Code,
não dentro do repositório do projeto. Isso permite reutilizá-los em múltiplos projetos.

### 1. Copiar os artefatos da fábrica para o contexto global

```powershell
# Identificar o diretório global do Claude Code
# Windows: C:\Users\<usuario>\.claude\
$ClaudeGlobal = "$env:USERPROFILE\.claude"

# Criar estrutura se não existir
New-Item -ItemType Directory -Force -Path "$ClaudeGlobal\agents"
New-Item -ItemType Directory -Force -Path "$ClaudeGlobal\commands"
New-Item -ItemType Directory -Force -Path "$ClaudeGlobal\skills"

# Copiar da fábrica para o contexto global
# (execute a partir do diretório raiz deste repositório)
Copy-Item ".claude\agents\*"   -Destination "$ClaudeGlobal\agents\"   -Recurse -Force
Copy-Item ".claude\commands\*" -Destination "$ClaudeGlobal\commands\" -Recurse -Force
Copy-Item ".claude\skills\*"   -Destination "$ClaudeGlobal\skills\"   -Recurse -Force
```

> **Nota:** Após esta etapa, os comandos `/fabricar-software`, `/aprovar`, etc. estarão
> disponíveis em qualquer projeto onde você abrir o Claude Code.

### 2. Autenticar o GitHub CLI

```powershell
gh auth login
```

### 3. Verificar a instalação

```powershell
claude --version
gh --version
git --version
```

---

## Iniciando um novo projeto

### Passo 1 — Clonar ou criar o repositório do projeto

```powershell
# Opção A: novo repositório
mkdir meu-projeto
cd meu-projeto
git init
git checkout -b main
git commit --allow-empty -m "chore: init"
gh repo create meu-projeto --private --source=. --push

# Opção B: repositório existente
git clone https://github.com/org/meu-projeto.git
cd meu-projeto
```

### Passo 2 — Copiar o CLAUDE.md base para o projeto

```powershell
# A partir do diretório raiz da fábrica nt-usina:
Copy-Item "CLAUDE.md" -Destination "caminho\do\seu\projeto\CLAUDE.md"
```

Edite o `CLAUDE.md` copiado e preencha a **Seção 1 — Identidade do Projeto**:

```yaml
fabrica: Natural Tecnologia
nome: meu-projeto
descricao: Descrição em 2-3 linhas do objetivo do sistema
cliente: Nome do Cliente
versao_atual: 0.1.0
data_inicio: 2026-03-26
```

### Passo 3 — Inicializar a estrutura do projeto

Execute a partir do diretório do **projeto** (não da fábrica):

```powershell
# Copiar o script de inicialização
Copy-Item "caminho\da\fabrica\scripts\Init-Projeto.ps1" -Destination "scripts\"

# Executar
.\scripts\Init-Projeto.ps1
```

O script cria:
```
docs\demanda\demanda-cliente.md   ← template da demanda
docs\bugs\                        ← bug reports (criados pelo Testing Agent)
docs\testes\                      ← relatórios de teste (criados pelo Testing Agent)
backlog\indice.json               ← estado do pipeline
docs\pipeline.log                 ← log de execução
```

### Passo 4 — Escrever a demanda do cliente

Edite `docs\demanda\demanda-cliente.md` com a demanda real do cliente.
Escreva em linguagem de negócio — o Agente PO interpretará e estruturará.

---

## Executando o pipeline

### Opção A — Ambiente completo (recomendado)

```powershell
# Copia o Start-Usina.ps1 para seu projeto e executa
.\scripts\Start-Usina.ps1
```

Abre o Windows Terminal com 4 painéis:
- **Painel 1:** Claude Code CLI (aqui você digita os comandos)
- **Painel 2:** Monitor do backlog (atualização automática)
- **Painel 3:** Git log (atualização automática)
- **Painel 4:** Log da aplicação

### Opção B — Claude Code direto

```powershell
cd caminho\do\seu\projeto
claude
```

### Iniciando o pipeline

No Claude Code CLI (Painel 1):

```
/fabricar-software
```

---

## Workflow em modo validação (padrão)

O modo `validacao` é o padrão e o recomendado durante testes.
O Orquestrador **para após cada etapa** e aguarda aprovação humana.

### Ciclo de aprovação

```
┌─────────────────────────────────────────────────────┐
│  1. /fabricar-software        → executa uma etapa   │
│  2. Revise o artefato gerado                        │
│  3. /aprovar                  → registra aprovação  │
│  4. /fabricar-software --retomar → próxima etapa    │
└─────────────────────────────────────────────────────┘
```

### Ciclo de reprovação

```
┌─────────────────────────────────────────────────────┐
│  1. /fabricar-software        → executa uma etapa   │
│  2. Identifica problemas no artefato                │
│  3. /reprovar <motivo>        → registra reprovação │
│  4. /fabricar-software --retomar → re-executa etapa │
└─────────────────────────────────────────────────────┘
```

### Etapas do pipeline e artefatos gerados

| # | Etapa | Agente | Artefato gerado |
|---|---|---|---|
| 1 | User Stories | PO | `docs\user-stories.md` |
| 2 | Requisitos | Analista | `docs\requirements.md` |
| 3 | Arquitetura | Arquiteto | `docs\architecture.md` |
| 4 | Backlog | PO/Tech Lead | `backlog\indice.json` + `backlog\grupo-*.json` |
| 5..N | Features | Coding + Testing | Código + `docs\testes\plano-*.md` |
| N+1 | Release | Git Specialist | Tag semver no repositório |
| N+2 | Deploy | Deploy Agent | Aplicação em produção |

---

## Comandos disponíveis

### Controle do pipeline

| Comando | Descrição |
|---|---|
| `/fabricar-software` | Inicia o pipeline completo |
| `/fabricar-software --retomar` | Retoma após aprovação, reprovação ou checkpoint |
| `/aprovar` | Aprova a etapa atual |
| `/reprovar <motivo>` | Reprova a etapa atual com motivo |
| `/set-modo validacao` | Ativa modo com aprovação humana por etapa |
| `/set-modo autonomo` | Ativa modo totalmente automático |

### Etapas individuais

| Comando | Descrição |
|---|---|
| `/po-processar-demanda` | Executa apenas o Agente PO |
| `/gerar-requirements` | Executa apenas o Analista de Requisitos |
| `/gerar-arquitetura` | Executa apenas o Arquiteto |
| `/gerar-backlog` | Executa apenas o PO/Tech Lead |
| `/feature-desenvolver <id>` | Desenvolve uma feature específica manualmente |
| `/testar-feature <id>` | Testa uma feature específica manualmente |
| `/feature-ajustar <id> "<desc>"` | Cria ajuste pós-merge em feature já entregue |

### Versionamento e deploy

| Comando | Descrição |
|---|---|
| `/versionamento-newBranch <id>` | Cria branch para uma feature |
| `/versionamento-branch-push <id>` | Commita e faz push da feature |
| `/versionamento-release patch\|minor\|major` | Cria tag de release semântica |
| `/deploy` | Executa deploy em produção |
| `/deploy --dry-run` | Simula o deploy sem executar |
| `/deploy --rollback` | Executa rollback para versão anterior |

### Utilitários

| Comando | Descrição |
|---|---|
| `/fabricar-tmux` | Abre ambiente de 4 painéis no Windows Terminal |
| `/gerar-contextDoc` | Gera documento de contexto consolidado do projeto |

---

## Agentes disponíveis

Os agentes são invocados automaticamente pelo Orquestrador ou manualmente pelos comandos acima.

| Agente | Responsabilidade |
|---|---|
| `orquestrador` | Gerencia o pipeline, despacha sub-agentes, mantém estado |
| `po` | Traduz demanda do cliente em user stories |
| `analista-requisitos` | Transforma user stories em requisitos técnicos estruturados |
| `arquiteto` | Define arquitetura, stack e estrutura do projeto |
| `po-tech-lead` | Cria backlog granular e executável |
| `git-specialist` | Gerencia branches, commits, PRs e merges |
| `coding-agent` | Implementa features seguindo a arquitetura definida |
| `testing-agent` | Valida implementações contra critérios de aceite |
| `deploy-agent` | Leva o código de main para produção |

---

## Skills disponíveis

Skills são guias técnicos injetados nos agentes de codificação como contexto:

| Skill | Quando usar |
|---|---|
| `boas-praticas` | Sempre (injetada automaticamente no Coding Agent) |
| `stack-laravel-vue` | Projetos Laravel + Vue.js 3 + PostgreSQL |
| `stack-javascript` | Projetos Node.js + Express |
| `stack-python` | Projetos Python + FastAPI |
| `stack-gcp` | Deploy e infraestrutura no Google Cloud Platform |
| `stack-baileys` | Integrações WhatsApp via Baileys |
| `stack-langchain` | Integrações com LLMs via LangChain |

---

## Status do backlog

O arquivo `backlog\indice.json` é a fonte de verdade do pipeline:

| Status | Descrição |
|---|---|
| `nao_iniciada` | Feature aguardando execução |
| `em_desenvolvimento` | Coding Agent trabalhando |
| `desenvolvimento_concluido` | Código pronto, aguardando testes |
| `em_testes` | Testing Agent validando |
| `concluida` | Aprovada nos testes e mergeada |
| `em_recuperacao` | Interrompida — aguardando decisão do Orquestrador |
| `bloqueada` | Falhou permanentemente — requer intervenção humana |

---

## Auto-reinício de sessão

A cada **10 features processadas**, o Orquestrador exibe um sinal de reinício:

```
════════════════════════════════════════════
  Checkpoint atingido — reinício necessário
  Execute: /fabricar-software --retomar
════════════════════════════════════════════
```

Isso previne degradação de contexto em projetos grandes. Execute:

```
/fabricar-software --retomar
```

---

## Recuperação após interrupção

Se o Claude Code for fechado no meio de uma feature:

```
/fabricar-software --retomar
```

O Orquestrador lê `backlog\indice.json`, detecta a feature interrompida (`feature_atual`)
e retoma de onde parou.

---

## Estrutura de arquivos do projeto

```
seu-projeto/
├── CLAUDE.md                      ← configuração do projeto (editar na seção 1)
├── backlog/
│   ├── indice.json                ← estado do pipeline (fonte de verdade)
│   └── grupo-NNN-NOME.json        ← detalhes das features por grupo
├── docs/
│   ├── demanda/
│   │   └── demanda-cliente.md     ← input: demanda do cliente
│   ├── user-stories.md            ← gerado: user stories
│   ├── requirements.md            ← gerado: requisitos técnicos
│   ├── architecture.md            ← gerado: arquitetura
│   ├── context-doc.md             ← gerado: contexto consolidado (/gerar-contextDoc)
│   ├── bugs/
│   │   └── bug-*.md               ← gerado: bug reports
│   ├── testes/
│   │   └── plano-*.md             ← gerado: relatórios de teste
│   └── pipeline.log               ← log de execução do pipeline
├── scripts/
│   ├── Init-Projeto.ps1           ← inicialização (execute uma vez)
│   └── Start-Usina.ps1            ← ambiente de 4 painéis
└── [código da aplicação]          ← gerado pelo Coding Agent
```

---

## Perguntas frequentes

**P: Posso usar a fábrica em múltiplos projetos simultaneamente?**
R: Não recomendado. A fábrica é projetada para execução sequencial (uma feature por vez).
Para múltiplos projetos, use instâncias separadas do Claude Code em diretórios diferentes.

**P: O que acontece se o Claude Code fechar no meio de uma feature?**
R: Execute `/fabricar-software --retomar`. O estado está salvo em `backlog\indice.json`.

**P: Posso editar os artefatos gerados (user-stories.md, requirements.md, etc.)?**
R: Sim, e é encorajado em modo `validacao`. Use `/reprovar <motivo>` para que o agente
corrija, ou edite manualmente e use `/aprovar` para prosseguir.

**P: A fábrica funciona com qualquer stack tecnológica?**
R: Sim. O Arquiteto escolhe a stack com base nos requisitos. As skills disponíveis cobrem
Laravel/Vue, Node.js, Python/FastAPI e GCP. Para outras stacks, o Coding Agent usa
`boas-praticas` como base e adapta conforme a arquitetura definida.

**P: Como adicionar uma nova skill para uma stack não coberta?**
R: Crie um arquivo `~/.claude/skills/stack-nome.md` seguindo o padrão dos existentes,
e adicione a referência na tabela de skills do `CLAUDE.md` do projeto.

---

*Natural Tecnologia — Fábrica de Software IA*
*Versão da fábrica: 0.2.0 — Atualizado em 2026-03-26*
