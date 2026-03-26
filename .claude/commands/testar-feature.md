# /testar-feature

Executa o Testing Agent para uma feature específica.
Verifica critérios de aceite, executa testes automatizados e analisa qualidade de código.

## Uso

```
/testar-feature <feature_id>
```

## Parâmetro

`<feature_id>` — ID da feature no formato `NNN-NNN`.

## O que este comando faz

```
1. Lê feature em backlog\grupo-NNN-*.json (criterios_aceite, escopo_tecnico)
2. Invoca Testing Agent com payload da feature
3. Testing Agent executa:
   a) Verificação de integridade do escopo (arquivos criados, endpoints implementados)
   b) Execução de testes automatizados (unitários + integração)
   c) Verificação de cobertura dos critérios de aceite
   d) Análise de qualidade de código
   e) Testes de UI no browser (se aplicável — via Claude in Chrome)
   f) Análise de logs
4. Resultado:
   APROVADO  → salva docs\testes\plano-<feature_id>.md
   REPROVADO → salva docs\bugs\bug-<timestamp>-<feature_id>.md
```

## Saída esperada

### Aprovação
```
✅ Feature 002-003 APROVADA
   Testes: 8 passando / 8 total
   Critérios: 4/4 cobertos
   Relatório: docs\testes\plano-002-003.md
```

### Reprovação
```
❌ Feature 002-003 REPROVADA
   Bugs encontrados: 2
   - BUG-001: Endpoint POST /api/v1/pedidos não valida campo 'quantity'
   - BUG-002: Teste test_create_order_with_empty_items falhando
   Bug report: docs\bugs\bug-20250115-1430-002-003.md
```

## Quando usar manualmente

- Testar uma feature específica durante desenvolvimento iterativo
- Re-testar após corrigir bugs manualmente
- Auditar feature já concluída após alterações no sistema

## Observação

Normalmente invocado automaticamente pelo Orquestrador após o Coding Agent.
Em modo `validacao`, o resultado é exibido e aguarda `/aprovar` ou `/reprovar`.
