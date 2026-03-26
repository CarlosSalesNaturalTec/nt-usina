# /versionamento-release

Cria uma tag de release semântica no repositório, preparando o projeto para deploy.
Deve ser executado quando todas as features do backlog estiverem com status `concluida`.

## Uso

```
/versionamento-release <versao>
/versionamento-release patch
/versionamento-release minor
/versionamento-release major
```

## Parâmetros

| Parâmetro | Descrição |
|---|---|
| `<versao>` | Versão explícita, ex: `1.2.3` |
| `patch` | Incrementa o patch: `1.2.3` → `1.2.4` |
| `minor` | Incrementa o minor: `1.2.3` → `1.3.0` |
| `major` | Incrementa o major: `1.2.3` → `2.0.0` |

## O que este comando faz

1. Verifica pré-condições de release
2. Determina a próxima versão
3. Cria tag anotada no repositório
4. Faz push da tag para o remoto
5. Registra em `docs\pipeline.log`

## Pré-condições verificadas

```
[ ] Branch atual é main
[ ] main está atualizada (git pull origin main)
[ ] Todos os testes passam
[ ] backlog\indice.json: todas features com status "concluida" ou "bloqueada"
[ ] Não existe tag com esta versão (evitar sobrescrever)
```

## Processo

```
1. Determinar versão atual:
   → Ler última tag: git describe --tags --abbrev=0
   → SE não existir tag: versão base = 0.1.0

2. Calcular nova versão:
   → SE parâmetro é "patch": incrementar terceiro número
   → SE parâmetro é "minor": incrementar segundo número, zerar terceiro
   → SE parâmetro é "major": incrementar primeiro número, zerar demais
   → SE parâmetro é versão explícita: usar diretamente

3. Validar que versão nova > versão atual (semver)

4. Criar tag anotada:
   git tag -a v<versao> -m "Release v<versao> — [data] — Natural Tecnologia"
   git push origin v<versao>

5. Registrar em pipeline.log:
   [TIMESTAMP] [INFO] [RELEASE] Tag v<versao> criada e publicada

6. Exibir resumo:
   - Tag criada: v<versao>
   - Commits incluídos: git log <tag-anterior>..HEAD --oneline
   - Próximo passo: /deploy
```

## Exemplos de uso

```
# Antes do primeiro deploy
/versionamento-release 1.0.0

# Após correção de bugs
/versionamento-release patch

# Após adicionar novas funcionalidades
/versionamento-release minor

# Após breaking changes na API
/versionamento-release major
```

## Próximo passo após release

```
/deploy
```

## Observações

- Tags seguem o padrão semver: `vMAJOR.MINOR.PATCH` (ex: `v1.2.3`)
- O Deploy Agent usa a tag criada aqui para identificar o que está sendo deployado
- Nunca deletar tags já publicadas — criar nova tag corretiva se necessário
