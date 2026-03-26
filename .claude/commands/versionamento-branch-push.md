# /versionamento-branch-push

Commita todo o trabalho da branch atual e faz push para o remoto.
Invoca o Git Specialist com operação `commit_push`.

## Uso

```
/versionamento-branch-push <feature_id>
/versionamento-branch-push <feature_id> "<mensagem de commit customizada>"
```

## Parâmetros

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `<feature_id>` | Sim | ID da feature para montar a mensagem de commit padrão |
| `"<mensagem>"` | Não | Mensagem customizada — sobrescreve o padrão gerado |

## O que este comando faz

```
1. Verifica que estamos em uma feature branch (nunca em main)
2. Verifica se há arquivos a commitar (git status)
3. Verifica ausência de código de debug:
   dd(), var_dump(), console.log(), print_r(), die()
4. Verifica ausência de .env nos arquivos staged
5. git add .
6. Monta mensagem no padrão Conventional Commits:
   feat(<grupo>): <titulo da feature em minúsculas>
   (ou usa a mensagem customizada se fornecida)
7. git commit -m "<mensagem>"
8. git push origin <branch-atual>
9. Retorna hash do commit criado
```

## Mensagem padrão gerada

```
feat(auth): implementar login com jwt
feat(pedidos): criar endpoint de pedidos
fix(relatorios): corrigir exportação de pdf com caracteres especiais
```

## Quando usar

Normalmente invocado automaticamente pelo Orquestrador após o Coding Agent.
Use manualmente para commitar trabalho incremental durante desenvolvimento.

## Proteções

- Bloqueia commit direto em `main`
- Bloqueia commit com arquivos de debug
- Bloqueia commit com `.env` staged
