# /feature-ajustar

Abre uma feature já concluída para ajuste pontual sem recriar branch ou backlog.
Útil para correções pós-merge ou melhorias solicitadas após entrega.

## Uso

```
/feature-ajustar <feature_id> "<descricao do ajuste>"
```

## Parâmetros

| Parâmetro | Descrição |
|---|---|
| `<feature_id>` | ID da feature no formato `NNN-NNN` |
| `"<descricao>"` | O que precisa ser ajustado — seja específico |

## Exemplos

```
/feature-ajustar 001-003 "Adicionar validação de força de senha no endpoint de cadastro"
/feature-ajustar 002-001 "Corrigir paginação que retorna itens duplicados"
/feature-ajustar 003-005 "Incluir campo 'observacao' no retorno do endpoint GET /pedidos"
```

## O que este comando faz

```
1. Lê a feature em backlog\grupo-NNN-*.json
2. Cria nova branch de ajuste: fix/<grupo>-<id>-<descricao-curta>
3. Cria entrada de ajuste em docs\bugs\ajuste-<timestamp>-<feature_id>.md
   com a descrição do que precisa ser feito
4. Coding Agent executa o ajuste com modo "corrigir"
5. Testing Agent valida o ajuste
6. Git Specialist faz commit: fix(<grupo>): <descricao> e push
7. Atualiza backlog com nota do ajuste realizado
```

## Diferença entre /feature-ajustar e ciclo de bugs

| | `/feature-ajustar` | Ciclo de bug (testing-agent) |
|---|---|---|
| **Quando** | Após feature concluída e mergeada | Durante desenvolvimento, antes do merge |
| **Branch** | Nova branch `fix/...` | Mesma branch de feature |
| **Iniciado por** | Humano (você) | Testing Agent (automático) |
| **Registrado em** | `docs\bugs\ajuste-*.md` | `docs\bugs\bug-*.md` |

## Quando usar

- Ajuste solicitado pelo cliente após demonstração
- Melhoria pontual identificada em code review
- Correção de comportamento não coberto pelos critérios de aceite originais
