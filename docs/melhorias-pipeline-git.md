# Melhorias Futuras — Pipeline Git

> Criado em: 2026-03-28
> Contexto: descobertas durante execução do pipeline no projeto ntUsina_paulo_afonso

---

## 1. Feature branches não são pushadas para o remoto

### Comportamento atual

O pipeline cria a branch localmente, faz commit, merge em `main` e push de `main`.
A feature branch **nunca é enviada ao remoto** quando o agente cai no caminho de fallback
do `merge_main` (merge local, sem PR).

**Raiz do problema:** a operação `merge_main` do `git-specialist.md` possui dois caminhos:

```
Caminho 1 — via PR (gh pr merge):   branch já está no remoto → ok
Caminho 2 — fallback local:         merge direto + push main → branch nunca é pushada
```

No caminho 2, o `git push origin --delete feature/<branch>` falha silenciosamente
porque a branch não existe no remoto.

### Impacto atual

| Aspecto | Impacto |
|---|---|
| Código da feature | Nenhum — está em main via merge commit `--no-ff` |
| Rastreabilidade | Baixo — merge commit preserva histórico no `git log --graph` |
| Pull Request no GitHub | Não existe para features sem branch remota |
| Code review via GitHub | Não acontece — revisão atual é feita via `/aprovar` |

**Conclusão:** impacto baixo no modelo atual (agente único + aprovação humana).
`main` atualizada no remoto é suficiente para a operação corrente.

### Melhoria recomendada

No caminho de fallback do `merge_main` (em `git-specialist.md`), garantir push da
feature branch **antes** do merge:

```
# Antes do merge local, adicionar:
git push --set-upstream origin <branch-atual>

# Sequência completa corrigida:
git push --set-upstream origin <branch-atual>   ← NOVO
git checkout main
git pull origin main
git merge --no-ff feature/<branch> -m "..."
git push origin main
git branch -d feature/<branch>
git push origin --delete feature/<branch>
```

### Quando implementar

Quando o projeto evoluir para um dos cenários abaixo:
- Múltiplos desenvolvedores trabalhando em paralelo
- PR formal no GitHub com diff visual, comentários e CI por feature
- Rastreabilidade de branch obrigatória por processo ou auditoria

---

## 2. Branches locais acumulam após merge

### Comportamento atual

Após o merge, a branch local **não é excluída** de forma consistente.
Branches se acumulam no repositório local com o tempo.

### Melhoria recomendada

Garantir que `git branch -d feature/<branch>` seja sempre executado após merge bem-sucedido,
independente do caminho (PR ou fallback local).

### Quando implementar

Pode ser implementado a qualquer momento — baixo risco, impacto apenas na limpeza local.

---

## 3. Features F-002 a F-010 sem branches individuais

### Comportamento observado

No projeto ntUsina_paulo_afonso, as features F-002 a F-010 foram commitadas em um único
commit direto em `main`, sem branches individuais:

```
c8c5400 feat(webhook): F-002 a F-010 — infra base e recepção de mensagens
```

Indica que o Orquestrador, em algum momento, executou múltiplas features sem passar
pelo ciclo `criar_branch → commit_push → merge_main` para cada uma.

### Melhoria recomendada

Adicionar validação no Orquestrador: antes de avançar o status de uma feature para
`concluida`, verificar se existe um merge commit referenciando o ID da feature no log
do `main`. Se não existir, emitir alerta.
