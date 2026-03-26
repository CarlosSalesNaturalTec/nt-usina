# /reprovar

Reprova o artefato ou etapa atual, registra o motivo e sinaliza ao Orquestrador para re-executar.
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

## O que este comando faz

1. Registra reprovação e motivo em `docs\pipeline.log`
2. Orquestrador re-executa o agente da etapa atual com o motivo como contexto adicional
3. Agente recebe: artefato anterior + motivo da reprovação → gera versão corrigida
4. Pipeline pausa novamente para nova aprovação

## Comportamento por etapa

| Etapa reprovada | Agente re-executado | Recebe como contexto extra |
|---|---|---|
| User Stories | PO | Motivo da reprovação |
| Requirements | Analista | Motivo da reprovação |
| Architecture | Arquiteto | Motivo da reprovação |
| Backlog | PO/Tech Lead | Motivo da reprovação |
| Feature (código) | Coding Agent | Motivo como bug report informal |
| Testes | — | Testing Agent já cria bug report formal |

## Observação

O motivo é salvo em `docs\pipeline.log` e serve como histórico de decisões.
Para features de código, prefira usar o ciclo natural de testes:
o Testing Agent cria bug reports detalhados automaticamente.
