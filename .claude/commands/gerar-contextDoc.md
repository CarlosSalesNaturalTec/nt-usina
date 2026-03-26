# /gerar-contextDoc

Gera um documento de contexto consolidado do projeto, útil para onboarding de novos
desenvolvedores, auditoria do pipeline ou para repassar contexto a um novo agente.

## Uso

```
/gerar-contextDoc
/gerar-contextDoc --saida <caminho>
```

## Parâmetros opcionais

| Flag | Descrição | Padrão |
|---|---|---|
| `--saida <caminho>` | Caminho do arquivo de saída | `docs\context-doc.md` |

## O que este comando faz

Consolida os principais artefatos do projeto em um único documento de contexto:

1. Lê `CLAUDE.md` — identidade, stack, modo de operação
2. Lê `docs\user-stories.md` — resumo executivo e épicos
3. Lê `docs\requirements.md` — resumo de RFs, RNFs e entidades
4. Lê `docs\architecture.md` — stack, estrutura de diretórios, padrões
5. Lê `backlog\indice.json` — estado atual do pipeline e progresso
6. Gera documento consolidado com referências cruzadas

## Artefato de saída

Salvo em `docs\context-doc.md` (ou caminho especificado):

```markdown
# Context Document — [Nome do Projeto]

> Gerado por: /gerar-contextDoc — Natural Tecnologia
> Data: [YYYY-MM-DD HH:MM]
> Versão do pipeline: [versão do indice.json]

---

## 1. Visão Geral do Projeto

[Resumo executivo do PO + objetivo do sistema do Analista]

---

## 2. Stack Tecnológica

[Tabela de stack da arquitetura]

---

## 3. Estrutura de Diretórios

[Estrutura definida pelo Arquiteto]

---

## 4. Principais Funcionalidades

[Épicos e user stories resumidas — sem critérios de aceite detalhados]

---

## 5. Entidades de Domínio

[Entidades e relacionamentos do requirements.md]

---

## 6. Padrões Técnicos Obrigatórios

[Autenticação, API, erros, logging — da arquitetura]

---

## 7. Estado do Pipeline

[Resumo do backlog: total, concluídas, em andamento, bloqueadas]

| Feature | Grupo | Status | Branch |
|---|---|---|---|
| [titulo] | [grupo] | [status] | [branch] |

---

## 8. Referências

- Demanda original: `docs\demanda\demanda-cliente.md`
- User Stories: `docs\user-stories.md`
- Requisitos: `docs\requirements.md`
- Arquitetura: `docs\architecture.md`
- Backlog: `backlog\indice.json`
```

## Quando usar

- Antes de adicionar um novo desenvolvedor humano ao projeto
- Ao retomar um projeto após longa pausa
- Para gerar contexto mínimo para um agente externo
- Para revisão gerencial do projeto
- Ao criar um novo projeto baseado em um projeto existente (como template de contexto)

## Observações

- Este documento é uma foto do estado atual — regenere sempre que precisar de versão atualizada
- Não substitui os artefatos originais — é apenas um consolidado para leitura humana rápida
- Artefatos ausentes são sinalizados com `[NÃO GERADO AINDA]`
