# /gerar-backlog

Executa apenas o agente PO/Tech Lead — decompõe a arquitetura em backlog estruturado e executável.

## Uso

```
/gerar-backlog
```

## O que este comando faz

1. Verifica se `docs\architecture.md` existe
2. Verifica se `CLAUDE.md` tem stack e estrutura de diretórios preenchidos
3. Invoca o **Agente PO/Tech Lead**
4. Agente gera `backlog\indice.json` e `backlog\grupo-NNN-NOME.json`
5. Em modo `validacao`: exibe resumo e aguarda `/aprovar` ou `/reprovar`

## Pré-requisito

`docs\architecture.md` deve existir (gerado por `/gerar-arquitetura`).

## Artefatos gerados

- `backlog\indice.json` — índice central com todas as features e estado do pipeline
- `backlog\grupo-NNN-NOME.json` — detalhamento por grupo funcional com escopo técnico

## Estrutura do backlog gerado

Cada feature contém:
- `id`, `titulo`, `descricao`
- `escopo_tecnico` — arquivos a criar/modificar, endpoints, migrations
- `criterios_aceite` — testáveis em formato Gherkin
- `skills_necessarias` — quais skills o Coding Agent deve consultar
- `status: "nao_iniciada"` — todas começam aqui

## Quando usar diretamente

- Arquitetura aprovada, hora de criar o backlog
- Backlog precisa ser regenerado após mudança arquitetural
- Adicionar novos grupos/features ao backlog existente

## Atenção

Se já existir `backlog\indice.json` com features em andamento,
o agente perguntará antes de sobrescrever para evitar perda de progresso.
