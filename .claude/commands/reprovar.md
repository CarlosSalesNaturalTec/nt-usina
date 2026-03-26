# /reprovar

Reprova o artefato ou etapa atual, registra o motivo e prepara o pipeline para re-execução.
Disponível apenas em modo `validacao`.

## Uso

```
/reprovar <motivo>
```

## Parâmetro obrigatório

`<motivo>` — descrição do que está incorreto ou precisa ser ajustado.
Seja específico: o agente responsável vai usar este texto para corrigir.

## Exemplos

```
/reprovar As user stories não cobrem o fluxo de recuperação de senha

/reprovar O documento de requisitos está sem RNFs de performance e segurança

/reprovar A arquitetura definiu MySQL mas o projeto usa PostgreSQL

/reprovar O backlog não tem o grupo de infraestrutura como primeiro grupo

/reprovar A feature não implementou validação no endpoint POST /api/v1/pedidos
```

## Fluxo completo em modo validação

O Orquestrador **para e retorna** após cada etapa. O ciclo de reprovação é:

```
1. Orquestrador executa uma etapa e PARA
2. Você revisa o artefato e identifica problemas
3. Execute /reprovar <motivo>       → registra reprovação com motivo
4. Execute /fabricar-software --retomar  → re-executa a etapa com o motivo como contexto
```

> **Importante:** `/reprovar` sozinho não re-executa a etapa.
> É necessário executar `/fabricar-software --retomar` em seguida.

## O que este comando faz

1. Registra reprovação e motivo em `docs\pipeline.log`
2. Exibe instrução para continuar o pipeline

## O que acontece na re-execução

Quando `/fabricar-software --retomar` é executado após reprovação:

1. Orquestrador lê o último motivo de reprovação no `pipeline.log`
2. Re-executa o agente da etapa atual com o motivo como contexto adicional
3. Agente recebe: artefato anterior + motivo da reprovação → gera versão corrigida
4. Pipeline para novamente para nova aprovação

## Comportamento por etapa

| Etapa reprovada | Agente re-executado | Recebe como contexto extra |
|---|---|---|
| User Stories | PO | Motivo da reprovação |
| Requirements | Analista | Motivo da reprovação |
| Architecture | Arquiteto | Motivo da reprovação |
| Backlog | PO/Tech Lead | Motivo da reprovação |
| Feature (código) | Coding Agent | Motivo como bug report informal |
| Testes | — | Testing Agent já cria bug report formal |

## O que é registrado no log

```
[YYYY-MM-DD HH:MM:SS] [WARN] [HUMANO] REPROVADO: <etapa> — Motivo: <motivo informado>
```

## Próximo passo após /reprovar

```
/fabricar-software --retomar
```

## Observação

O motivo é salvo em `docs\pipeline.log` e serve como histórico de decisões.
Para features de código, prefira usar o ciclo natural de testes:
o Testing Agent cria bug reports detalhados automaticamente.
