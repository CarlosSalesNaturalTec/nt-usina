# /fabricar-software

Entry point da fábrica nt-usina. Inicia ou retoma o pipeline completo de desenvolvimento.

## Uso

```
/fabricar-software
/fabricar-software --retomar
```

## O que este comando faz

Invoca o **Agente Orquestrador**, que gerencia o pipeline completo de desenvolvimento.

### Fluxo ao executar `/fabricar-software` (sem flag)

1. Orquestrador lê `backlog\indice.json`
2. Detecta a fase atual do pipeline (`pipeline.fase_atual`)
3. Se `planejamento` ou ausente → inicia cadeia de planejamento (PO → Analista → Arquiteto → PO/Tech Lead)
4. Se `desenvolvimento` → inicia loop de features
5. Se `deploy` → invoca deploy-agent
6. Se `concluido` → exibe resumo final

### Fluxo ao executar `/fabricar-software --retomar`

Retoma o pipeline a partir do último estado gravado em `indice.json`.
Usado em dois cenários:

**a) Após `/aprovar` em modo validação:**
```
/aprovar                         ← registra aprovação no log
/fabricar-software --retomar     ← Orquestrador lê log, confirma aprovação e avança
```

**b) Após `/reprovar <motivo>` em modo validação:**
```
/reprovar <motivo>               ← registra reprovação no log
/fabricar-software --retomar     ← Orquestrador lê log, re-executa etapa com o motivo
```

**c) Após checkpoint de auto-reinício (a cada 10 features):**
```
                                 ← Orquestrador exibe sinal de reinício e para
/fabricar-software --retomar     ← nova sessão com context window zerada
```

**d) Após interrupção inesperada:**
```
/fabricar-software --retomar     ← Orquestrador detecta feature_atual no indice.json e retoma
```

## Pré-requisitos

- `docs\demanda\demanda-cliente.md` deve existir com a demanda do cliente
  → Execute `scripts\Init-Projeto.ps1` para criar a estrutura de diretórios
- Git inicializado no projeto (`git init` + remote configurado)
- Branch `main` existente
- `operacao.modo` definido em `CLAUDE.md` (padrão: `validacao`)

## Verificações automáticas antes de iniciar

```
[ ] docs\demanda\demanda-cliente.md existe e não está vazio
[ ] Git inicializado (git rev-parse --git-dir)
[ ] Branch main existe
[ ] operacao.modo definido em CLAUDE.md (padrão: validacao)
```

## Comportamento por modo de operação

### Modo `validacao` (padrão recomendado)

O Orquestrador **para e retorna** após cada etapa principal. O operador humano deve:
1. Revisar o artefato gerado
2. Executar `/aprovar` ou `/reprovar <motivo>`
3. Executar `/fabricar-software --retomar` para continuar

Este é o modo esperado durante testes e calibração da fábrica.

### Modo `autonomo`

O Orquestrador executa o loop completo sem interrupções.
Só pausa em caso de erro crítico ou ao atingir o checkpoint de 10 features.

## Exemplo de uso inicial

```
# 1. Inicializar estrutura do projeto
.\scripts\Init-Projeto.ps1

# 2. Escrever ou colar a demanda do cliente em:
#    docs\demanda\demanda-cliente.md

# 3. Iniciar o pipeline
/fabricar-software
```

## Parâmetros opcionais

| Flag | Descrição |
|---|---|
| `--retomar` | Retoma a partir do último checkpoint gravado em `indice.json` |

## Observações

- O progresso é sempre salvo em `backlog\indice.json` — seguro interromper a qualquer momento
- O Orquestrador nunca re-invoca comandos por conta própria — sempre sinaliza ao operador
- Em modo `validacao`, cada execução do `/fabricar-software --retomar` processa exatamente uma etapa
