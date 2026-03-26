# /fabricar-software

Entry point da fábrica nt-usina. Inicia ou retoma o pipeline completo de desenvolvimento.

## Uso

```
/fabricar-software
/fabricar-software --retomar
```

## O que este comando faz

Invoca o **Agente Orquestrador** passando o modo de invocação detectado.

### Fluxo ao executar `/fabricar-software` (sem flag)

1. Orquestrador lê `backlog\indice.json`
2. Detecta a fase atual do pipeline (`pipeline.fase_atual`)
3. Se `planejamento` ou ausente → inicia cadeia de planejamento (PO → Analista → Arquiteto → PO/Tech Lead)
4. Se `desenvolvimento` → inicia loop de features
5. Se `deploy` → invoca deploy-agent
6. Se `concluido` → exibe resumo final

### Fluxo ao executar `/fabricar-software --retomar`

Invocado automaticamente pelo Orquestrador após auto-reinício (a cada 10 features).
Orquestrador pula o bootstrap de planejamento e vai direto para recovery + loop.

## Pré-requisitos

- `docs\demanda\demanda-cliente.md` deve existir com a demanda do cliente
- Git inicializado no projeto (`git init` + remote configurado)
- Variáveis de ambiente configuradas (`.env`)

## Verificações automáticas antes de iniciar

```
[ ] docs\demanda\demanda-cliente.md existe e não está vazio
[ ] Git inicializado (git rev-parse --git-dir)
[ ] Branch main existe
[ ] operacao.modo definido em CLAUDE.md (padrão: validacao)
```

## Exemplo de uso inicial

```
# 1. Criar a demanda do cliente
# Escrever ou colar em: docs\demanda\demanda-cliente.md

# 2. Iniciar o pipeline
/fabricar-software
```

## Parâmetros opcionais

| Flag | Descrição |
|---|---|
| `--retomar` | Retoma a partir do último checkpoint gravado em `indice.json` |

## Observações

- Em modo `validacao` (padrão), o pipeline pausa após cada etapa para aprovação
- Em modo `autonomo`, roda sem interrupção até conclusão ou erro crítico
- O progresso é sempre salvo em `backlog\indice.json` — seguro interromper a qualquer momento
