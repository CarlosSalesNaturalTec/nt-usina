# Skill: Boas Práticas de Programação
# Natural Tecnologia — nt-usina
# Arquivo: .claude/skills/boas-praticas.md
#
# USO: Injetada em TODO agente de codificação.
# Referência rápida — não é tutorial. Aplicar sempre.

---

## SOLID

| Princípio | Regra prática |
|---|---|
| **S** — Single Responsibility | Uma classe/função = uma razão para mudar. Se você precisa usar "e" para descrever o que ela faz, divida. |
| **O** — Open/Closed | Aberta para extensão, fechada para modificação. Use herança, interfaces ou injeção para variar comportamento. |
| **L** — Liskov Substitution | Subclasses devem poder substituir a classe pai sem quebrar o sistema. Nunca sobrescreva para lançar `NotImplementedException`. |
| **I** — Interface Segregation | Interfaces pequenas e específicas. Cliente não deve depender de métodos que não usa. |
| **D** — Dependency Inversion | Dependa de abstrações, não de implementações concretas. Injete dependências, não as instancie dentro da classe. |

---

## Clean Code — Regras essenciais

### Nomenclatura
```
✓ Nomes revelam intenção:       getUserActiveOrders()   vs   getU()
✓ Evitar abreviações:           calculateTotalPrice()   vs   calcTP()
✓ Substantivos para classes:    OrderService, UserRepository
✓ Verbos para funções:          processPayment(), validateEmail()
✓ Booleanos com prefixo:        isActive, hasPermission, canDelete
✓ Constantes em UPPER_SNAKE:    MAX_RETRY_ATTEMPTS, DEFAULT_TIMEOUT
```

### Funções
```
✓ Máximo 20 linhas por função (ideal: 5-10)
✓ Máximo 3 parâmetros — se precisar de mais, use objeto/DTO
✓ Sem efeitos colaterais ocultos
✓ Retornar um tipo consistente — nunca null em alguns casos e objeto em outros
✓ Falhar cedo: validar entradas no início, retornar/lançar antes de processar
```

### Classes
```
✓ Máximo 200-300 linhas — se passar, provavelmente viola SRP
✓ Poucas responsabilidades públicas (ideal: 3-5 métodos públicos)
✓ Dependências via construtor (injeção)
✓ Evitar herança profunda (mais de 2 níveis = sinal de problema)
```

### Comentários
```
✓ Comentar O QUE NÃO É ÓBVIO — decisões de negócio, workarounds, limitações
✗ Nunca comentar o que o código já diz:
  // incrementa i por 1       →  i++
  // retorna o usuário         →  return user
✓ Preferir código autoexplicativo a comentários explicativos
✓ TODO/FIXME devem ter dono e data: // TODO(carlos): remover após migração — 2025-03
```

---

## Design Patterns — quando usar

### Criacionais
| Pattern | Usar quando |
|---|---|
| **Factory Method** | Criação de objetos com lógica variável por tipo |
| **Builder** | Objeto com muitos parâmetros opcionais de construção |
| **Singleton** | Recurso compartilhado que deve ter exatamente 1 instância (ex: config, logger) |

### Estruturais
| Pattern | Usar quando |
|---|---|
| **Repository** | Isolar acesso a dados da lógica de negócio |
| **Adapter** | Integrar interface incompatível (ex: API externa com interface própria) |
| **Decorator** | Adicionar comportamento a um objeto sem modificar sua classe |
| **Facade** | Simplificar interface de subsistema complexo |

### Comportamentais
| Pattern | Usar quando |
|---|---|
| **Strategy** | Algoritmos intercambiáveis (ex: cálculo de frete por transportadora) |
| **Observer** | Notificar múltiplos objetos sobre mudanças de estado (eventos) |
| **Command** | Encapsular operação como objeto (ex: filas, desfazer) |
| **Chain of Responsibility** | Processar requisição por cadeia de handlers (ex: middleware) |

---

## Tratamento de Erros

```
✓ Use exceções para erros excepcionais — não para fluxo normal
✓ Crie exceções específicas do domínio:
    OrderNotFoundException > Exception genérica
✓ Nunca engolir exceções silenciosamente:
    catch (Exception $e) { }  → PROIBIDO
✓ Log antes de re-lançar ou ao tratar definitivamente
✓ Retorne erros claros para o cliente — nunca exponha stack trace em produção
✓ Valide entradas o mais cedo possível (fail fast)
```

---

## Testes

```
Estrutura AAA:
  Arrange  → preparar dados e estado
  Act      → executar a ação sendo testada
  Assert   → verificar o resultado

✓ 1 assertion principal por teste (pode ter assertions secundárias)
✓ Nome do teste descreve o cenário:
    test_user_cannot_login_with_invalid_password()
✓ Testar comportamento, não implementação interna
✓ Testes independentes — não dependem de ordem de execução
✓ Mocks apenas para dependências externas (banco, APIs, filas)
✓ Dados de teste isolados — nunca usar dados de produção
```

---

## Segurança — regras básicas

```
✓ Nunca confiar em input do usuário — validar e sanitizar sempre
✓ Nunca construir queries com concatenação de strings (SQL injection)
✓ Nunca logar dados sensíveis (senhas, tokens, CPF, cartão)
✓ Nunca commitar .env, chaves, secrets
✓ Usar variáveis de ambiente para toda configuração sensível
✓ Hash de senhas com algoritmo forte (bcrypt, argon2)
✓ Tokens com expiração definida
✓ Rate limiting em endpoints públicos e de autenticação
```

---

## Code Smells — detectar e eliminar

| Smell | Sintoma | Solução |
|---|---|---|
| Long Method | Função > 20 linhas | Extrair métodos |
| God Class | Classe faz tudo | Dividir por responsabilidade |
| Feature Envy | Método usa muito dados de outra classe | Mover o método para lá |
| Duplicate Code | Mesmo código em 2+ lugares | Extrair para função/método compartilhado |
| Magic Numbers | `if (status == 3)` | Constantes nomeadas: `if (status == ORDER_CANCELLED)` |
| Deep Nesting | if dentro de if dentro de for... | Early return, guard clauses |
| Long Parameter List | Função com 4+ params | Agrupar em DTO/objeto |

---

## Checklist antes de todo commit

```
[ ] Sem console.log / dd() / var_dump() / die()
[ ] Sem credenciais hardcoded
[ ] Sem TODO antigos sem dono
[ ] Sem código comentado (remover ou implementar)
[ ] Nomes descritivos em variáveis, funções e classes
[ ] Testes passando
[ ] Sem imports não utilizados
```
