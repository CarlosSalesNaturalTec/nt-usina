# /set-modo

Altera o modo de operação do pipeline entre `validacao` e `autonomo`.

## Uso

```
/set-modo validacao
/set-modo autonomo
/set-modo            ← exibe o modo atual sem alterar
```

## Modos disponíveis

### `validacao` (padrão recomendado na fase inicial)

```
O Orquestrador pausa após cada etapa e exibe um resumo do artefato gerado.
Pipeline aguarda /aprovar ou /reprovar antes de prosseguir.

Use durante:
  → Fase inicial de testes e calibração da fábrica
  → Projetos críticos onde cada decisão precisa de revisão humana
  → Quando quiser analisar os artefatos intermediários
```

### `autonomo`

```
O Orquestrador executa o pipeline completo sem pausas.
Apenas erros críticos (bloqueios) interrompem para intervenção.
Todas as ações são registradas em docs\pipeline.log para auditoria posterior.

Use após:
  → Validação e confiança estabelecida no pipeline
  → Projetos com backlog bem definido e baixo risco
  → Quando quiser máxima velocidade de entrega
```

## O que este comando faz

1. Atualiza `operacao.modo` no `CLAUDE.md`
2. Registra a mudança em `docs\pipeline.log`
3. A mudança tem efeito imediato na próxima iteração do Orquestrador

## Verificar modo atual

```
/set-modo
```

Exibe:
```
Modo atual: validacao
Última alteração: 2025-01-15 14:30:00
```

## Observação

A mudança de `validacao` → `autonomo` durante o pipeline em execução
tem efeito na próxima pausa — se o Orquestrador já está aguardando `/aprovar`,
execute `/aprovar` primeiro e então mude o modo.
