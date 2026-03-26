# CLAUDE.md — Contexto Global do Projeto

> Este arquivo é lido automaticamente pelo Claude Code em toda sessão.
> Ele define o contexto, regras e convenções que todos os agentes devem seguir.
>
> **Fábrica de Software:** Natural Tecnologia
> **Modelo de execução:** Claude Code CLI — 100% local

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
  # validacao  → Orquestrador pausa após cada etapa e aguarda aprovação humana
  #              Use durante fase inicial de testes e calibração da fábrica
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

## 6. Estado do Pipeline

> Atualizado automaticamente pelo Orquestrador.

```yaml
pipeline:
  fase_atual: [planejamento | desenvolvimento | testes | deploy | concluido]
  ultima_atualizacao: [TIMESTAMP]
  features_total: 0
  features_concluidas: 0
  features_em_andamento: 0
  features_em_recuperacao: 0
  features_bloqueadas: 0
  ultimo_checkpoint: [TIMESTAMP — usado para recovery após interrupção]
```

---

## 7. Caminhos de Artefatos

```yaml
artefatos:
  demanda_cliente:   docs/demanda/demanda-cliente.md
  user_stories:      docs/user-stories.md
  requirements:      docs/requirements.md
  architecture:      docs/architecture.md
  backlog_indice:    backlog/indice.json
  backlog_grupos:    backlog/grupo-*.json
  bugs:              docs/bugs/
  planos_teste:      docs/testes/
```

---

## 7. Regras Globais para Todos os Agentes

### 7.1 Antes de qualquer ação
- Ler este arquivo (`CLAUDE.md`) para garantir contexto atualizado
- Verificar o artefato de entrada definido para sua etapa
- Confirmar que o artefato de entrada existe antes de prosseguir

### 7.2 Ao produzir artefatos
- Salvar sempre no caminho definido na seção 7
- Nunca sobrescrever sem verificar se existe versão anterior
- Incluir timestamp e versão no cabeçalho de documentos `.md`

### 7.3 Qualidade de código
- Aplicar sempre os princípios definidos em `@.claude/skills/boas-praticas.md`
- Toda função/método deve ter responsabilidade única (SRP)
- Código deve ser autoexplicativo; comentários apenas para decisões não óbvias
- Nunca deixar `console.log`, `dd()`, `var_dump()` ou código de debug em commits

### 7.4 Sobre o backlog
- O arquivo `backlog/indice.json` é a **única fonte de verdade** sobre o estado do pipeline
- Nenhum agente altera o status de uma feature sem concluir sua tarefa por completo
- Status só avança — nunca retrocede sem criação de registro em `docs/bugs/`
- Status `em_recuperacao` indica item interrompido; Orquestrador decide entre retomar ou resetar

### 7.5 Comunicação entre agentes
- Agentes não se comunicam diretamente — toda comunicação é via arquivos em disco
- O Orquestrador é o único agente que lê o backlog e aciona outros agentes
- Agentes especializados (PO, Analista, etc.) não acionam outros agentes

### 7.6 Recovery após interrupção
- Ao iniciar, o Orquestrador sempre verifica itens com status `em_desenvolvimento` ou `em_testes`
- Se branch existe para o item → retoma do último commit (re-executa agente com contexto do que já existe)
- Se branch não existe → reseta status para `nao_iniciada` e reinicia do zero
- Toda mudança de status grava `ultimo_checkpoint` imediatamente no `indice.json`

### 7.7 Modo de operação
- Verificar `operacao.modo` neste arquivo antes de prosseguir entre etapas
- Em modo `validacao`: exibir resumo do artefato gerado e aguardar `/aprovar` ou `/reprovar`
- Em modo `autonomo`: prosseguir automaticamente; registrar log de cada etapa em `docs/pipeline.log`

---

## 8. TMux — Sessão de Trabalho

A sessão TMux da Natural Tecnologia organiza o ambiente de monitoramento em 4 painéis:

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

> Para iniciar a sessão: `bash scripts/tmux-fabrica.sh`
> Ou via slash command: `/fabricar-tmux`

---

## 9. Skills Disponíveis

| Skill | Arquivo | Quando usar |
|---|---|---|
| Boas Práticas | `@.claude/skills/boas-praticas.md` | Todo agente de codificação |
| Laravel + Vue.js | `@.claude/skills/stack-laravel-vue.md` | Projetos com essa stack |
| GCP | `@.claude/skills/stack-gcp.md` | Deploy e infraestrutura GCP |
| Python + FastAPI | `@.claude/skills/stack-python.md` | Projetos Python |
| Baileys (WhatsApp) | `@.claude/skills/stack-baileys.md` | Integrações WhatsApp |
| LangChain | `@.claude/skills/stack-langchain.md` | Integrações com LLMs |

> Para usar uma skill, inclua no prompt do agente: `Consulte @.claude/skills/nome-da-skill.md`

---

## 10. Configurações de Ambiente

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

## 11. Histórico de Decisões Arquiteturais (ADR)

> Registrar aqui decisões importantes que impactam todo o projeto.
> Formato: data | decisão | justificativa

| Data | Decisão | Justificativa |
|---|---|---|
| — | — | — |

---

*Natural Tecnologia — Fábrica de Software IA*
*Atualizar este arquivo a cada mudança significativa de contexto.*
