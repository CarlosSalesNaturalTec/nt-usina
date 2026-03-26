# /gerar-arquitetura

Executa apenas o agente Arquiteto de Software — define stack, arquitetura e estrutura do projeto.

## Uso

```
/gerar-arquitetura
```

## O que este comando faz

1. Verifica se `docs\requirements.md` existe
2. Invoca o **Agente Arquiteto de Software**
3. Agente gera `docs\architecture.md`
4. Agente atualiza seções 2 (Stack) e 3 (Estrutura de Diretórios) do `CLAUDE.md`
5. Em modo `validacao`: exibe resumo e aguarda `/aprovar` ou `/reprovar`

## Pré-requisito

`docs\requirements.md` deve existir (gerado por `/gerar-requirements`).

## Artefatos gerados/atualizados

- `docs\architecture.md` — decisões arquiteturais, stack, padrões técnicos, infraestrutura
- `CLAUDE.md` seções 2 e 3 — stack e estrutura de diretórios preenchidos

## Quando usar diretamente

- Requirements aprovados, hora de definir a arquitetura
- Stack precisa ser revisada ou alterada
- Novo projeto com requirements já prontos

## Observação

Após execução, revisar `CLAUDE.md` para confirmar que stack e estrutura
foram preenchidos corretamente antes de gerar o backlog.
