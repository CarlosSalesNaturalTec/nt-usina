# /versionamento-newBranch

Cria uma nova branch de feature a partir de main atualizada.
Invoca o Git Specialist com operação `criar_branch`.

## Uso

```
/versionamento-newBranch <feature_id>
/versionamento-newBranch 002-004
```

## Parâmetro

`<feature_id>` — ID da feature. O nome da branch será montado automaticamente
a partir do grupo, id e nome da feature no `indice.json`.

## O que este comando faz

```
1. Lê feature_id em backlog\indice.json para obter grupo e nome
2. Verifica se há mudanças não commitadas (aborta se houver)
3. git checkout main
4. git pull origin main
5. git checkout -b feature/<grupo>-<id>-<descricao>
6. Confirma que a branch foi criada
7. Atualiza feature.branch em indice.json
```

## Branch criada

```
feature/<grupo>-<id>-<descricao-curta-kebab-case>

Exemplos:
  feature/auth-001-login-jwt
  feature/pedidos-002-criar-pedido
  feature/relatorios-004-exportar-pdf
```

## Quando usar manualmente

Normalmente invocado automaticamente pelo Orquestrador.
Use manualmente quando precisar criar a branch de uma feature
sem executar o ciclo de desenvolvimento completo.

## Verificações de segurança

- Nunca cria branch a partir de outra feature branch — sempre de main
- Aborta se working directory tiver mudanças não commitadas
