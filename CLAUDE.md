# CLAUDE.md — Contexto Global do Projeto

> Este arquivo é lido automaticamente pelo Claude Code em toda sessão.
> Ele define o contexto, regras e convenções que todos os agentes devem seguir.
>
> **Fábrica de Software:** Natural Tecnologia
> **Repositório:** CarlosSalesNaturalTec/nt-usina
> **Modelo de execução:** Claude Code CLI — Windows (PowerShell)
>
> **Arquitetura de contexto:**
> Os agentes (`.claude/agents/`), comandos (`.claude/commands/`) e skills (`.claude/skills/`)
> vivem no **contexto global do usuário** (`~/.claude/`) e são reutilizáveis em múltiplos projetos.
> Este `CLAUDE.md` é o único artefato da fábrica que fica **dentro do repositório do projeto**,
> personalizando o comportamento da fábrica para este projeto específico.
> Veja `README.md` para instruções de configuração inicial.

---

## 1. Identidade do Projeto

```yaml
fabrica: Natural Tecnologia
nome: [DEFINIR — substituir ao iniciar projeto]
descricao: [DEFINIR — 2 a 3 linhas sobre o objetivo do sistema]
cliente: [DEFINIR]
versao_atual: 0.1.0
data_inicio: [DEFINIR]
```

---

## 2. Stack Tecnológica

> Preenchido pelo Arquiteto de Software após análise de requisitos.
> Substituir os placeholders abaixo quando o artefato `docs/architecture.md` for gerado.

```yaml
stack:
  backend: [DEFINIR — ex: Laravel 11 + PHP 8.3]
  frontend: [DEFINIR — ex: Vue.js 3 + Vite]
  banco_de_dados: [DEFINIR — ex: PostgreSQL 16]
  infraestrutura: [DEFINIR — ex: GCP Cloud Run + Cloud SQL]
  autenticacao: [DEFINIR — ex: JWT + Laravel Sanctum]
  outras_dependencias: []
```

---

## 3. Estrutura de Diretórios do Código-Fonte

> Preenchido pelo Arquiteto de Software.

```
[DEFINIR após geração de docs/architecture.md]
```

---

## 4. Estratégia de Versionamento

- **Modelo:** GitHub Flow
- **Branch principal:** `main` (sempre deployável)
- **Branches de feature:** `feature/<grupo>-<id>-<descricao-curta>`
- **Commits:** seguir Conventional Commits

### Padrão de Conventional Commits

```
<tipo>(<escopo>): <descrição curta>

Tipos permitidos:
  feat     → nova funcionalidade
  fix      → correção de bug
  refactor → refatoração sem mudança de comportamento
  test     → adição ou correção de testes
  docs     → alterações em documentação
  chore    → tarefas de manutenção (deps, config)
  style    → formatação, sem alteração de lógica

Exemplos:
  feat(auth): implementar login com JWT
  fix(dashboard): corrigir cálculo de totais mensais
  test(api): adicionar testes unitários para UserController
```

---

## 5. Modo de Operação

```yaml
operacao:
  modo: validacao   # validacao | autonomo
  # validacao  → Orquestrador executa uma etapa, exibe resumo e ENCERRA
  #              Operador revisa o artefato, digita /aprovar ou /reprovar,
  #              depois re-executa /fabricar-software --retomar para avançar
  # autonomo   → Loop contínuo sem intervenção; apenas erros críticos pausam
  #              Use após validação e confiança estabelecida no pipeline
```

> Para alterar o modo sem editar este arquivo manualmente:
> - `/set-modo validacao`
> - `/set-modo autonomo`

**Comandos disponíveis no modo `validacao`:**
- `/aprovar` — aprova o artefato atual e avança para próxima etapa
- `/reprovar <motivo>` — reprova o artefato, registra motivo e re-executa a etapa

---

## 6. Execução Sequencial e Contexto

> **Fase atual:** execução sequencial — uma feature por vez.
> Paralelismo e git worktrees são previstos para fases futuras após estabilização do pipeline.

### Princípio do mínimo contexto necessário

Cada agente recebe **apenas** o que precisa para sua tarefa. Nunca o projeto inteiro.

| Agente | Recebe | NÃO recebe |
|---|---|---|
| PO | Demanda do cliente | Código, arquitetura, backlog |
| Analista | `user-stories.md` | Código, backlog |
| Arquiteto | `requirements.md` | Código, backlog |
| PO/Tech Lead | `architecture.md` | Código, stories completas |
| Coding Agent | Feature específica + trecho relevante da arquitetura + skills da stack | Outras features, bugs de outras features |
| Testing Agent | Feature específica + critérios de aceite | Backlog completo, arquitetura |
| Deploy Agent | Checklist de deploy + configs de ambiente | Código-fonte, histórico de bugs |

### Arquitetura de contexto do Orquestrador

O Orquestrador usa a **`Agent` tool para todos os sub-agentes** e **checkpoint a cada 10 features**:

**Por iteração — o Orquestrador lê APENAS:**
- `backlog\indice.json` — estado do pipeline
- Campo `operacao.modo` do `CLAUDE.md` — `validacao` ou `autonomo`

**Por iteração — o Orquestrador despacha via `Agent` tool:**
- `Agent(coding-agent, prompt contendo: feature_id + trecho_arquitetura + skills_necessarias)`
- `Agent(testing-agent, prompt contendo: feature_id + criterios_aceite)`
- Recebe de volta **apenas**: `{feature_id, status_resultado, resumo_curto}`
- Sub-agentes **nunca** retornam código, logs completos ou artefatos volumosos
- Todo conteúdo produzido fica em disco (`docs\bugs\`, `docs\testes\`)

**Checkpoint a cada 10 features processadas:**
- "Processada" = status alterado para `concluida` ou `bloqueada` nesta sessão
- Ao atingir o limiar: grava checkpoint em `indice.json` → exibe sinal de reinício → ENCERRA
- Operador executa `/fabricar-software --retomar` → nova instância com context window zerada continua do ponto exato

**Estado do pipeline vive em disco — nunca na memória do processo.**

---

## 7. Estado do Pipeline

> Atualizado automaticamente pelo Orquestrador.

```yaml
pipeline:
  fase_atual: [planejamento | desenvolvimento | testes | deploy | concluido]
  ultima_atualizacao: [TIMESTAMP]
  ultimo_checkpoint: [TIMESTAMP]
  features_total: 0
  features_concluidas: 0
  features_em_andamento: 0
  features_em_recuperacao: 0
  features_bloqueadas: 0
  feature_atual: null         # ID da feature em execução no momento
  features_processadas_sessao: 0  # Contador para auto-reinício (limiar: 10)
  testes_habilitado: false    # Etapa de testes. Ativar com /fabricar-software --testes=on
```

---

## 8. Caminhos de Artefatos

```yaml
artefatos:
  demanda_cliente:   docs\demanda\demanda-cliente.md
  user_stories:      docs\user-stories.md
  requirements:      docs\requirements.md
  architecture:      docs\architecture.md
  backlog_indice:    backlog\indice.json
  backlog_grupos:    backlog\grupo-*.json
  bugs:              docs\bugs\
  planos_teste:      docs\testes\
  pipeline_log:      docs\pipeline.log
```

---

## 9. Regras Globais para Todos os Agentes

### 9.1 Antes de qualquer ação
- Ler este arquivo (`CLAUDE.md`) para garantir contexto atualizado
- Verificar o artefato de entrada definido para sua etapa
- Confirmar que o artefato de entrada existe antes de prosseguir
- Receber apenas o contexto mínimo necessário (ver tabela na seção 6)

### 9.2 Ao produzir artefatos
- Salvar sempre no caminho definido na seção 8
- Nunca sobrescrever sem verificar se existe versão anterior
- Incluir timestamp e versão no cabeçalho de documentos `.md`

### 9.3 Qualidade de código
- Aplicar sempre os princípios definidos em `@.claude/skills/boas-praticas.md`
- Toda função/método deve ter responsabilidade única (SRP)
- Código deve ser autoexplicativo; comentários apenas para decisões não óbvias
- Nunca deixar `console.log`, `dd()`, `var_dump()` ou código de debug em commits

### 9.4 Sobre o backlog
- O arquivo `backlog\indice.json` é a **única fonte de verdade** sobre o estado do pipeline
- Nenhum agente altera o status de uma feature sem concluir sua tarefa por completo
- Status só avança — nunca retrocede sem criação de registro em `docs\bugs\`
- Status `em_recuperacao` indica item interrompido; Orquestrador decide entre retomar ou resetar

### 9.5 Comunicação entre agentes
- Agentes não se comunicam diretamente — toda comunicação é via arquivos em disco
- O Orquestrador é o único agente que lê o backlog e aciona outros agentes
- Agentes especializados (PO, Analista, etc.) não acionam outros agentes

### 9.6 Recovery após interrupção
- Ao iniciar, o Orquestrador verifica `feature_atual` no `indice.json`
- Se `feature_atual` não for null → feature estava em execução quando o processo foi interrompido
  - Status `em_desenvolvimento` → re-executa coding-agent com contexto do que já existe em disco
  - Status `em_testes` → re-executa testing-agent
  - Status `em_recuperacao` → Orquestrador decide entre retomar ou resetar para `nao_iniciada`
- Toda mudança de status grava `ultimo_checkpoint` imediatamente no `indice.json`

### 9.7 Modo de operação
- Verificar `operacao.modo` neste arquivo antes de prosseguir entre etapas
- Em modo `validacao`: exibir resumo do artefato gerado e ENCERRAR; operador digita `/aprovar` ou `/reprovar` e re-executa `/fabricar-software --retomar`
- Em modo `autonomo`: prosseguir automaticamente; registrar log em `docs\pipeline.log`

---

## 10. Windows Terminal — Sessão de Trabalho

```
┌─────────────────────────┬──────────────────────┐
│  PAINEL 1               │  PAINEL 2            │
│  Claude Code CLI        │  Pipeline Monitor    │
│  (orquestrador ativo)   │  backlog + workers   │
├─────────────────────────┼──────────────────────┤
│  PAINEL 3               │  PAINEL 4            │
│  Git log                │  Log da aplicação    │
└─────────────────────────┴──────────────────────┘
```

> Para iniciar a sessão: `.\scripts\Start-Usina.ps1` (PowerShell)
> Ou via slash command: `/fabricar-tmux`

---

## 11. Skills e Comandos Disponíveis

### Skills (guias técnicos para agentes de codificação)

| Skill | Arquivo | Quando usar |
|---|---|---|
| Boas Práticas | `~/.claude/skills/boas-praticas.md` | Todo agente de codificação |
| Laravel + Vue.js | `~/.claude/skills/stack-laravel-vue.md` | Projetos com essa stack |
| JavaScript / Node.js | `~/.claude/skills/stack-javascript.md` | Projetos JS/Node.js |
| GCP | `~/.claude/skills/stack-gcp.md` | Deploy e infraestrutura GCP |
| Python + FastAPI | `~/.claude/skills/stack-python.md` | Projetos Python |
| Baileys (WhatsApp) | `~/.claude/skills/stack-baileys.md` | Integrações WhatsApp |
| LangChain | `~/.claude/skills/stack-langchain.md` | Integrações com LLMs |

> Agentes leem skills via ferramenta `Read` no caminho `~/.claude/skills/<nome>.md`

### Comandos disponíveis (slash commands)

| Comando | Descrição |
|---|---|
| `/fabricar-software` | Entry point — inicia ou retoma o pipeline. Flags: `--retomar`, `--testes=on` |
| `/aprovar` | Aprova etapa atual (modo validacao) |
| `/reprovar <motivo>` | Reprova etapa atual com motivo (modo validacao) |
| `/set-modo validacao\|autonomo` | Altera modo de operação |
| `/po-processar-demanda` | Executa Agente PO isoladamente |
| `/gerar-requirements` | Executa Analista de Requisitos |
| `/gerar-arquitetura` | Executa Arquiteto |
| `/gerar-backlog` | Executa PO/Tech Lead |
| `/gerar-contextDoc` | Gera documento de contexto consolidado |
| `/feature-desenvolver <id>` | Desenvolve feature manualmente |
| `/testar-feature <id>` | Testa feature manualmente |
| `/feature-ajustar <id> "<desc>"` | Ajuste pós-merge |
| `/versionamento-newBranch <id>` | Cria branch de feature |
| `/versionamento-branch-push <id>` | Commit + push da feature |
| `/versionamento-release patch\|minor\|major` | Cria tag de release |
| `/deploy` | Deploy em produção |
| `/fabricar-tmux` | Abre ambiente de 4 painéis |

---

## 12. Configurações de Ambiente

> Preenchido durante setup do projeto. Nunca commitar valores reais.

```yaml
ambiente:
  desenvolvimento:
    url_base: http://localhost:[PORTA]
    banco: [DEFINIR]
  producao:
    url_base: [DEFINIR]
    plataforma: [DEFINIR — ex: GCP Cloud Run]

variaveis_de_ambiente:
  arquivo_local: .env
  arquivo_exemplo: .env.example
  vault: [DEFINIR — ex: GCP Secret Manager]
```

---

## 13. Histórico de Decisões Arquiteturais (ADR)

| Data | Decisão | Justificativa |
|---|---|---|
| — | GitHub Flow | Simplicidade: main + feature branches |
| — | Execução sequencial (1 feature por vez) | Simplicidade na fase inicial; paralelismo previsto para fases futuras |
| — | Orquestrador via `Agent` tool + checkpoint a cada 10 features | `Agent` tool isola sub-agentes; checkpoint previne degradação de contexto em projetos longos; operador re-executa `/fabricar-software --retomar` |
| — | Sub-agentes retornam apenas metadados | Evita que resultados volumosos contaminem o contexto do Orquestrador |

---

*Natural Tecnologia — Fábrica de Software IA*
*Atualizar este arquivo a cada mudança significativa de contexto.*