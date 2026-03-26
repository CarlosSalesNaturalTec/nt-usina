# /gerar-requirements

Executa apenas o agente Analista de Requisitos — transforma user stories em documento de requisitos técnicos.

## Uso

```
/gerar-requirements
```

## O que este comando faz

1. Verifica se `docs\user-stories.md` existe
2. Invoca o **Agente Analista de Requisitos**
3. Agente gera `docs\requirements.md`
4. Em modo `validacao`: exibe resumo e aguarda `/aprovar` ou `/reprovar`

## Pré-requisito

`docs\user-stories.md` deve existir (gerado por `/po-processar-demanda`).

## Artefato gerado

`docs\requirements.md` — requisitos funcionais (RF), não funcionais (RNF),
regras de negócio (RN), entidades de domínio e matriz de rastreabilidade.

## Quando usar diretamente

- User stories foram aprovadas e agora é hora de gerar os requisitos
- Requirements precisam ser regenerados após alteração nas stories
- Revisão isolada desta etapa

## Observação

Não avança automaticamente para arquitetura.
Use `/fabricar-software` para o pipeline completo.
