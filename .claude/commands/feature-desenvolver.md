# /feature-desenvolver

Executa o ciclo completo de desenvolvimento de uma feature específica do backlog:
branch → coding → commit → testes → aprovação.

## Uso

```
/feature-desenvolver <feature_id>
/feature-desenvolver 001-003
```

## Parâmetro

`<feature_id>` — ID da feature no formato `NNN-NNN` conforme `backlog\indice.json`.

## O que este comando faz

Executa manualmente o ciclo que o Orquestrador executaria automaticamente:

```
1. Lê a feature em backlog\grupo-NNN-*.json
2. Verifica dependências (features que precisam estar concluídas antes)
3. Git Specialist → cria branch feature/<grupo>-<id>-<descricao>
4. Coding Agent → implementa a feature
5. Git Specialist → commit + push
6. Testing Agent → executa testes
7. Se aprovado → feature.status = "concluida"
8. Se reprovado → cria bug report → Coding Agent corrige → re-testa
```

## Quando usar

- Desenvolver uma feature específica fora do loop automático do Orquestrador
- Retomar desenvolvimento de uma feature específica manualmente
- Testar o ciclo completo de uma feature durante validação da fábrica

## Pré-requisitos

- Feature deve existir em `backlog\indice.json` com status `nao_iniciada` ou `em_recuperacao`
- Dependências da feature devem estar com status `concluida`
- `docs\architecture.md` deve existir

## Exemplo de saída esperada

```
[feature-desenvolver] Iniciando feature 001-003: implementar-login-jwt
[feature-desenvolver] Branch criada: feature/auth-001-003-login-jwt
[feature-desenvolver] Coding Agent em execução...
[feature-desenvolver] Commit: feat(auth): implementar login com jwt
[feature-desenvolver] Testing Agent em execução...
[feature-desenvolver] ✅ Feature 001-003 APROVADA
```
