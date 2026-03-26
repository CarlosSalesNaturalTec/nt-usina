# /aprovar

Aprova o artefato ou etapa atual e registra a decisão no log do pipeline.
Disponível apenas em modo `validacao`.

## Uso

```
/aprovar
```

## O que este comando faz

1. Registra aprovação em `docs\pipeline.log` com timestamp
2. Exibe instrução para continuar o pipeline

## Fluxo completo em modo validação

O Orquestrador **para e retorna** após cada etapa. O ciclo correto é:

```
1. Orquestrador executa uma etapa e PARA
2. Você revisa o artefato gerado
3. Execute /aprovar          → registra aprovação
4. Execute /fabricar-software --retomar  → continua o pipeline
```

> **Importante:** `/aprovar` sozinho não continua o pipeline.
> É necessário executar `/fabricar-software --retomar` em seguida.

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

## O que é registrado no log

```
[YYYY-MM-DD HH:MM:SS] [INFO] [HUMANO] APROVADO: <etapa> — operador aprovou e solicitou continuação
```

## Próximo passo após /aprovar

```
/fabricar-software --retomar
```

## Ver modo atual

```
/set-modo
```
