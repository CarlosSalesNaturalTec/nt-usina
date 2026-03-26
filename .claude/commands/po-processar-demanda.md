# /po-processar-demanda

Executa apenas o agente PO — processa a demanda do cliente e gera user stories.
Útil para re-executar ou ajustar esta etapa individualmente sem rodar o pipeline completo.

## Uso

```
/po-processar-demanda
```

## O que este comando faz

1. Verifica se `docs\demanda\demanda-cliente.md` existe
2. Invoca o **Agente PO** com o conteúdo da demanda
3. Agente gera `docs\user-stories.md`
4. Em modo `validacao`: exibe resumo e aguarda `/aprovar` ou `/reprovar`

## Pré-requisito

`docs\demanda\demanda-cliente.md` deve existir com a demanda do cliente preenchida.

## Artefato gerado

`docs\user-stories.md` — user stories com critérios de aceite em formato Gherkin.

## Quando usar diretamente

- Primeira execução do planejamento
- Demanda foi alterada e as stories precisam ser regeradas
- Stories foram reprovadas e precisam de revisão

## Observação

Este comando não avança automaticamente para a próxima etapa.
Use `/fabricar-software` para executar o pipeline completo em sequência.
