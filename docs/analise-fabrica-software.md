# Análise Completa da Fábrica de Software IA — nt-usina

> **Data:** 2026-03-26
> **Autor:** Análise gerada por Claude Sonnet 4.6
> **Versão do projeto analisado:** 0.1.0

---

## 1. Visão Geral do Pipeline Mapeado

```
demanda-cliente.md
       ↓
  [PO Agent]  →  user-stories.md
       ↓
  [Analista]  →  requirements.md
       ↓
  [Arquiteto] →  architecture.md + CLAUDE.md (§2/§3)
       ↓
 [PO/TechLead] → indice.json + grupo-*.json
       ↓
 [Orquestrador] loop:
   ├─ [Git Specialist] criar_branch
   ├─ [Coding Agent]   implementar
   ├─ [Git Specialist] commit_push + abrir_pr
   ├─ [Testing Agent]  testar
   └─ [Git Specialist] merge_main
       ↓
  [Deploy Agent]
```

O fluxo conceitual é **coerente e bem estruturado**. Os artefatos cobrem todas as etapas necessárias para entregar software. Porém, há problemas que, se não resolvidos, **impediriam a execução autônoma real**.

---

## 2. Problemas Críticos

### 2.1 Mecanismo `Task()` — Abstração sem Implementação

O `CLAUDE.md` e o `orquestrador.md` descrevem que o Orquestrador usa `Task()` para despachar sub-agentes:

```
Task(coding-agent, {feature_id, trecho_arquitetura, skills_necessarias})
```

**Problema:** `Task()` não é um conceito nativo do Claude Code — é uma abstração inventada. No Claude Code real, os mecanismos são:
- **`Agent` tool** → spawn de sub-agentes (`.claude/agents/*.md`)
- **`TaskCreate` tool** → tarefas em background (diferente de agentes)

Os arquivos em `.claude/agents/` são definições de persona/comportamento, não contratos de chamada com assinatura tipada. O Orquestrador não tem instruções de **como exatamente invocar** um sub-agente com payload estruturado.

**Impacto:** O Orquestrador, como está descrito, não consegue executar o loop autônomo sem que o operador humano saiba mapear `Task()` → `Agent tool call` manualmente.

---

### 2.2 Auto-Reinício a Cada 10 Features — Mecanismo Impossível

O CLAUDE.md §6 e `orquestrador.md` descrevem:

> Ao atingir 10 features: grava checkpoint → **encerra** → **re-invoca `/fabricar-software --retomar`**

**Problema:** Um sub-agente (instância do Orquestrador invocada via Agent tool) **não pode re-invocar um slash command** da sessão pai. O slash command `/fabricar-software --retomar` existe no contexto do Claude Code CLI principal, não dentro do sub-agente. O sub-agente pode apenas retornar um resultado.

**Solução necessária:** O Orquestrador deveria retornar um sinal explícito `{"action": "reiniciar", "checkpoint": ...}` e a sessão pai (o humano ou o comando principal) seria responsável por re-executar `/fabricar-software --retomar`. Isso precisa estar documentado como responsabilidade do operador.

---

### 2.3 Modo `validacao` — Pausa/Retomada Tecnicamente Indefinida

O `orquestrador.md` diz que em modo `validacao` o Orquestrador "exibe resumo e aguarda `/aprovar`". O comando `/aprovar` "registra no pipeline.log e sinaliza o Orquestrador para avançar".

**Problema:** O Orquestrador **não está rodando** quando o humano digita `/aprovar`. Ele já terminou sua execução e retornou. O `/aprovar` escreve no log, mas não existe um mecanismo de IPC (Inter-Process Communication) para "sinalizar" um processo que não está mais em execução.

**Fluxo real necessário mas não documentado:**
```
1. /fabricar-software → Orquestrador roda → gera artefato → PARA
2. Humano lê artefato → digita /aprovar → log atualizado
3. Humano digita /fabricar-software novamente (ou --retomar)
4. Orquestrador relê indice.json → continua do ponto correto
```

O passo 3 está implícito mas **nunca escrito explicitamente** em nenhum artefato.

---

## 3. Problemas Significativos

### 3.1 Atualização do `CLAUDE.md` em Sessão Ativa

O Arquiteto é instruído a atualizar as seções 2 e 3 do `CLAUDE.md` com o stack definido. O PO/Tech Lead, que vem logo depois, **precisa ler essas seções**.

**Problema:** O `CLAUDE.md` é carregado pelo Claude Code no **início da sessão**. Alterações feitas em disco durante a sessão podem **não ser refletidas** automaticamente na context window dos sub-agentes subsequentes — dependendo de como a sessão e os sub-agentes são gerenciados.

**Mitigação:** O PO/Tech Lead poderia ler o `CLAUDE.md` via `Read` tool explicitamente. Mas a instrução atual diz apenas "recebe CLAUDE.md seções 2/3" sem especificar que deve fazer um `Read` explícito.

---

### 3.2 Software do Cliente Misturado com Artefatos da Fábrica

O Git Specialist cria branches `feature/<grupo>-<id>-...` no **repositório atual** (`nt-usina`). Isso significa que o código do cliente é desenvolvido **no mesmo repositório** que contém os prompts, agents, skills e scripts da fábrica.

**Problemas:**
- O `.dockerignore` do `stack-gcp.md` exclui `.claude/`, `docs/`, `backlog/` — mas essas exclusões precisam ser configuradas manualmente
- O deploy faria build de um repositório que mistura código de produção com metadados da fábrica
- Contamina o histórico git do produto final

**Solução recomendada:** A fábrica deveria operar em um diretório separado, com o projeto do cliente em um repositório próprio. O Git Specialist precisaria saber qual é o repositório-alvo.

---

### 3.3 Artefatos Referenciados mas Ausentes

| Referência | Local | Status |
|---|---|---|
| `08-versionamento-release` | Listado no system-reminder como skill | **Arquivo não existe** em `.claude/commands/` |
| `02-gerar-contextDoc` | Listado no system-reminder como skill | **Arquivo não existe** em `.claude/commands/` |
| `docs/demanda/demanda-cliente.md` | Pré-requisito do `/po-processar-demanda` | **Diretório `docs/demanda/` não existe**, sem comando para criar |
| `docs/bugs/`, `docs/testes/` | Caminhos de output dos agentes | **Diretórios não existem**, criados apenas em runtime |

---

### 3.4 `git add .` — Staging Indiscriminado

O `git-specialist.md` usa `git add .` antes de verificar arquivos problemáticos. A checklist de segurança (`.env`, debug code) ocorre **após o staging**, o que é backward. Se o commit falhar por um `.env` detectado, o arquivo já foi staged e precisa de `git reset HEAD`.

---

### 3.5 Princípio do Mínimo Contexto — Violado pelo `CLAUDE.md`

O CLAUDE.md §6 define claramente a tabela de "o que cada agente recebe". Mas como o CLAUDE.md é **injetado automaticamente em toda sessão Claude Code**, **todos os agentes recebem tudo** que está nele — incluindo seções irrelevantes ao seu papel.

O Coding Agent recebe o estado do pipeline, regras do PO, configurações de deploy, etc. O princípio do mínimo contexto é aspiracional, não tecnicamente garantido.

---

## 4. Análise de Contexto — Riscos de Estouro

### 4.1 Mapa de Consumo por Agente (estimativas)

```
┌────────────────────┬──────────────────────────────────────────┬──────────┐
│ Agente             │ Fontes de Contexto                       │ Estimado │
├────────────────────┼──────────────────────────────────────────┼──────────┤
│ PO                 │ CLAUDE.md + demanda-cliente.md           │ ~5k tok  │
│ Analista           │ CLAUDE.md + user-stories.md              │ ~8k tok  │
│ Arquiteto          │ CLAUDE.md + requirements.md              │ ~12k tok │
│ PO/Tech Lead       │ CLAUDE.md + architecture.md              │ ~15k tok │
│ Orquestrador (iter)│ CLAUDE.md + indice.json (cresce)         │ ~8-30k   │
│ Git Specialist     │ CLAUDE.md + payload                      │ ~5k tok  │
│ Coding Agent       │ CLAUDE.md + feature + skills + código    │ ⚠ 40-80k │
│ Testing Agent      │ CLAUDE.md + feature + output de testes   │ ⚠ 50-120k│
│ Deploy Agent       │ CLAUDE.md + architecture.md + checklist  │ ~15k tok │
└────────────────────┴──────────────────────────────────────────┴──────────┘
```

### 4.2 Coding Agent — Risco Médio-Alto

Contexto acumulado em uma invocação típica:
```
CLAUDE.md                         ~3.500 tokens
coding-agent.md instructions      ~2.000 tokens
boas-praticas.md (Read explícito) ~2.500 tokens
stack-laravel-vue.md              ~4.000 tokens
stack-gcp.md                      ~2.000 tokens
feature payload (JSON)            ~   800 tokens
architecture excerpt               ~1.500 tokens
Arquivos lidos (código existente)  ~5.000-20.000 tokens
Código gerado (em resposta)        ~3.000-15.000 tokens
─────────────────────────────────────────────────
TOTAL                             ~25.000-51.000 tokens
```

Dentro do limite de 200k tokens para claude-sonnet-4-6. **Risco baixo** para features de complexidade média.

**Risco real surge em:** features de refatoração ou funcionalidades que requerem leitura de 15+ arquivos existentes — pode atingir 100k+ tokens.

### 4.3 Testing Agent — Risco Alto

Este é o agente com maior risco de estouro:

```
CLAUDE.md + instructions          ~5.500 tokens
feature payload                   ~   800 tokens
Output de: php artisan test -v    ~10.000-50.000 tokens (*)
Output de: pytest -v              ~5.000-30.000 tokens (*)
Arquivos de teste lidos           ~5.000-15.000 tokens
Browser automation screenshots    variável
─────────────────────────────────────────────────
TOTAL                             ~20.000-100.000+ tokens
```

> (*) Output verboso de testes em projetos com 200+ testes pode gerar 50k+ tokens facilmente.

**Não há instrução no `testing-agent.md`** para limitar o output (ex: usar `--stop-on-failure`, capturar apenas falhas, usar `--compact`). Este é o ponto de maior vulnerabilidade de estouro.

### 4.4 Orquestrador — Risco de Degradação Progressiva

O Orquestrador é projetado para rodar em loop. O auto-reinício a cada 10 features previne degradação — **se funcionar**. Sem o auto-reinício, após ~20-30 features o Orquestrador acumularia:
- Resultados de Task calls anteriores
- Histórico de conversação da sessão
- Log de decisões

Podendo atingir facilmente 150k+ tokens em projetos grandes.

---

## 5. Inconsistências Menores

| # | Inconsistência | Arquivo | Impacto |
|---|---|---|---|
| 1 | `git add .` antes da checklist de segurança | `git-specialist.md` | Risco de commit acidental de arquivos sensíveis |
| 2 | Deploy-agent hardcoded para GCP/VPS, sem fallback para AWS/Azure | `deploy-agent.md` | Inutilizável para projetos não-GCP sem adaptação |
| 3 | `Start-Usina.ps1` auto-detecta log do Laravel/Python mas não Node.js/FastAPI | `scripts/Start-Usina.ps1` | Painel 4 pode ficar vazio |
| 4 | `indice.json` inicial tem schema diferente do schema completo do PO/Tech Lead | `po-tech-lead.md` vs `backlog/indice.json` | Recovery logic pode falhar na leitura de campos ausentes |
| 5 | `coding-agent.md` proíbe tocar em migrations já executadas, mas não há mecanismo para saber quais foram executadas | `coding-agent.md` | Agente não tem como verificar — regra sem enforcement |
| 6 | `testing-agent.md` menciona "browser tests via Claude in Chrome" sem verificar se a extensão está disponível | `testing-agent.md` | Falha silenciosa em ambientes sem a extensão |
| 7 | Sub-agentes "retornam apenas metadados" mas não há contrato formal de schema de retorno | `orquestrador.md` | Orquestrador pode receber respostas em formato imprevisível |

---

## 6. Diagnóstico Final

### O que funciona bem

- **Estrutura conceitual** é sólida: separação clara de responsabilidades, pipeline sequencial com estado persistido em disco
- **Skills** estão bem escritas e são genuinamente úteis como context injection
- **`boas-praticas.md`** é abrangente e aplicável independente de stack
- **Recovery e modo `em_recuperacao`** bem pensados para interrupções
- **Git Specialist** tem validações de segurança importantes (`.env`, debug code)
- **Auto-reinício a cada 10 features** é a decisão arquitetural mais inteligente — o problema é apenas a implementação

### O que impediria a entrega de software hoje

| Bloqueador | Severidade |
|---|---|
| `Task()` sem mapeamento para ferramenta real do Claude Code | **Crítico** |
| Modo `validacao` sem mecanismo técnico de pausa/retomada | **Crítico** |
| Auto-reinício inimplementável como descrito | **Crítico** |
| Testing Agent sem controle de verbosidade de output | **Alto** |
| Software do cliente no mesmo repo da fábrica | **Alto** |

### Veredicto

> A fábrica **entregaria software** com **operação semi-manual** — onde o humano atua como "cola" entre as etapas, executando commands explicitamente, lendo artefatos e re-invocando agentes. O modo **`autonomo` puro não é tecnicamente realizável** no estado atual. Seria necessário refinar 3 mecanismos críticos antes de um loop verdadeiramente autônomo funcionar.

---

## 7. Recomendações Prioritárias

1. **Documentar o contrato real de invocação de agentes** — substituir `Task()` por instruções explícitas de uso do `Agent` tool com o payload estruturado como string de prompt
2. **Redefinir o ciclo de validação** — documentar que em modo `validacao` o Orquestrador retorna após cada etapa e o operador re-executa `/fabricar-software --retomar`
3. **Redefinir o auto-reinício** — o Orquestrador retorna `{"reiniciar": true}` e o operador executa `/fabricar-software --retomar`
4. **Adicionar ao `testing-agent.md`** controles de output: capturar apenas failures, usar flags `--compact`/`--stop-on-failure`, limitar linhas de log
5. **Criar repositório separado para o projeto do cliente** — fábrica e produto em repos distintos
6. **Criar os arquivos ausentes**: `/versionamento-release`, `/gerar-contextDoc`, script de inicialização do `docs/demanda/`
7. **Schema de retorno formal** para todos os sub-agentes — JSON tipado que o Orquestrador pode parsear deterministicamente
