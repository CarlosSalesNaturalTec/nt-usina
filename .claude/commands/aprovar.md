# /aprovar

Aprova o artefato ou etapa atual e sinaliza ao Orquestrador para prosseguir.
Disponível apenas em modo `validacao`.

## Uso

```
/aprovar
```

## O que este comando faz

1. Registra aprovação em `docs\pipeline.log`
2. Orquestrador avança para a próxima etapa do pipeline

## Quando usar

Após revisar e aprovar qualquer um destes artefatos ou etapas:

| Etapa | Artefato revisado |
|---|---|
| PO concluído | `docs\user-stories.md` |
| Analista concluído | `docs\requirements.md` |
| Arquiteto concluído | `docs\architecture.md` |
| Backlog gerado | `backlog\indice.json` |
| Feature desenvolvida | Código na branch atual |
| Feature testada | `docs\testes\plano-NNN-NNN.md` |
| Pré-deploy | Checklist de deploy |

## Observação

Só funciona quando o Orquestrador está aguardando aprovação (modo `validacao`).
Em modo `autonomo`, este comando não tem efeito — o pipeline já avança automaticamente.

## Ver modo atual

```
/set-modo
```
