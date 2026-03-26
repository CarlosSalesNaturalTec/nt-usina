# /deploy

Executa o Deploy Agent — leva o código de main para o ambiente de produção.

## Uso

```
/deploy
/deploy --ambiente producao
/deploy --dry-run
```

## Parâmetros opcionais

| Flag | Descrição |
|---|---|
| `--ambiente producao` | Padrão. Deploy para produção conforme `docs\architecture.md` |
| `--dry-run` | Executa todas as verificações e exibe o plano, sem fazer deploy |

## Pré-requisitos obrigatórios

```
[ ] Todas as features do backlog estão com status "concluida" ou "bloqueada"
[ ] Branch main está atualizada com todos os merges
[ ] Suite completa de testes passa em main
[ ] Variáveis de ambiente de produção configuradas na plataforma
[ ] .env.example atualizado com novas variáveis
```

## O que este comando faz

```
1. Checklist pré-deploy (ver pré-requisitos acima)
   → SE qualquer item falhar: aborta e reporta o que está pendente

2. git checkout main && git pull origin main

3. Exibe log de commits desde o último deploy (git log)

4. Cria tag de versão: git tag -a v<versao> && git push origin v<versao>

5. Build da aplicação (conforme stack em architecture.md):
   → Laravel: composer install --no-dev && npm run build
   → Python: pip install -r requirements.txt
   → Node.js: npm ci --production

6. Deploy na plataforma (conforme architecture.md seção 9):
   → GCP Cloud Run: gcloud builds submit + gcloud run deploy
   → VPS: push via SSH + restart de serviços

7. Executa migrations em produção

8. Health check — verifica se a aplicação está respondendo

9. Smoke tests nos endpoints críticos

10. Registra em docs\pipeline.log e atualiza pipeline.fase_atual = "concluido"
```

## Dry run

```
/deploy --dry-run
```

Exibe o plano completo sem executar:
- Lista de commits que serão deployados
- Versão que será criada
- Comandos que serão executados
- Variáveis de ambiente necessárias

Útil para revisar antes de um deploy em produção.

## Rollback

Em caso de falha no health check, o Deploy Agent executa rollback automático
para a versão anterior e registra o erro em `docs\pipeline.log`.

Para rollback manual:
```
/deploy --rollback
```

## Em modo `validacao`

O comando exibe o checklist pré-deploy e aguarda `/aprovar` antes de prosseguir
com o deploy efetivo. Isso permite uma revisão humana final.
