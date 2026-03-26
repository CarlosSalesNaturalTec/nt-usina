# Skill: JavaScript — Node.js + ES6+ + Padrões
# Natural Tecnologia — nt-usina
# Arquivo: .claude/skills/stack-javascript.md
#
# USO: Injetar no Coding Agent para projetos JavaScript/Node.js.
# Cobre: Node.js (backend), JS moderno (ES2020+), Express, padrões gerais.

---

## Configuração base do projeto

### package.json essencial

```json
{
  "type": "module",
  "engines": { "node": ">=20.0.0" },
  "scripts": {
    "start":   "node src/index.js",
    "dev":     "node --watch src/index.js",
    "test":    "node --experimental-vm-modules node_modules/.bin/jest",
    "lint":    "eslint src/"
  }
}
```

### jsconfig.json (projetos sem TypeScript)

```json
{
  "compilerOptions": {
    "module": "ESNext",
    "target": "ESNext",
    "moduleResolution": "bundler",
    "checkJs": true,
    "strict": true
  },
  "include": ["src/**/*"]
}
```

---

## ES2020+ — Recursos obrigatórios

### Desestruturação e spread

```javascript
// ✓ Desestruturação de objetos com valor padrão
const { nome, email, role = 'user' } = usuario

// ✓ Desestruturação de arrays
const [primeiro, segundo, ...restantes] = lista

// ✓ Spread para clonar/mesclar sem mutar
const atualizado = { ...usuario, role: 'admin' }
const combinado  = [...lista1, ...lista2]

// ✓ Parâmetros com desestruturação
function criarPedido({ userId, items, desconto = 0 }) { }
```

### Async/Await — padrão obrigatório

```javascript
// ✓ Sempre async/await — nunca .then().catch() encadeados
async function processarPedido(id) {
    try {
        const pedido  = await pedidoRepo.findById(id)
        const usuario = await usuarioRepo.findById(pedido.userId)
        return await notificarUsuario(usuario, pedido)
    } catch (error) {
        logger.error('Erro ao processar pedido', { id, error: error.message })
        throw new DomainError(`Falha ao processar pedido ${id}`)
    }
}

// ✓ Paralelo quando independentes
const [pedido, estoque] = await Promise.all([
    pedidoRepo.findById(id),
    estoqueService.verificar(produtoId),
])

// ✓ Promise.allSettled quando falhas parciais são aceitáveis
const resultados = await Promise.allSettled(envios.map(enviar))
const falhas = resultados.filter(r => r.status === 'rejected')
```

### Optional chaining e Nullish coalescing

```javascript
// ✓ Optional chaining — evita TypeError
const cidade = usuario?.endereco?.cidade
const primeiroTag = post?.tags?.[0]

// ✓ Nullish coalescing — apenas null/undefined (não falsy)
const nome = usuario.nome ?? 'Anônimo'
const porta = config.porta ?? 3000

// ✗ Evitar OR para defaults — captura falsy indesejado
const porta = config.porta || 3000  // retorna 3000 se porta === 0
```

### Classes e módulos

```javascript
// ✓ Classes com campos privados (ES2022)
class OrderService {
    #repo
    #logger

    constructor(repo, logger) {
        this.#repo   = repo
        this.#logger = logger
    }

    async create(data) {
        this.#validar(data)
        const order = await this.#repo.save(data)
        this.#logger.info('Pedido criado', { id: order.id })
        return order
    }

    #validar(data) {
        if (!data.items?.length) throw new ValidationError('Items são obrigatórios')
    }
}

// ✓ ES Modules (não CommonJS em projetos novos)
export class OrderService { }
export default OrderService

import { OrderService } from './orderService.js'  // extensão obrigatória com type: module
```

---

## Node.js — Padrões de projeto

### Estrutura de projeto Express

```
src/
├── index.js               # Entrypoint — inicializa app e servidor
├── app.js                 # Instância Express — rotas, middleware, error handler
├── config/
│   └── index.js           # Todas as configs via process.env
├── routes/
│   └── v1/
│       ├── index.js       # Agrega routers da v1
│       └── orders.js      # Router específico
├── controllers/           # Orquestração: req → service → res
├── services/              # Lógica de negócio
├── repositories/          # Acesso a dados
├── models/                # Definições de schema/modelo
├── middlewares/
│   ├── auth.js            # Verificação de JWT
│   ├── validate.js        # Validação com Zod/Joi
│   └── errorHandler.js    # Handler global de erros
├── lib/
│   ├── logger.js          # Configuração do logger (pino)
│   └── database.js        # Conexão com banco
└── tests/
    ├── unit/
    └── integration/
```

### Express — padrões

```javascript
// app.js
import express from 'express'
import { errorHandler } from './middlewares/errorHandler.js'
import { v1Router } from './routes/v1/index.js'

const app = express()

app.use(express.json())
app.use(express.urlencoded({ extended: true }))

app.use('/api/v1', v1Router)

// Error handler sempre por último
app.use(errorHandler)

export default app

// middlewares/errorHandler.js
export function errorHandler(err, req, res, next) {
    const status  = err.statusCode ?? 500
    const message = err.isOperational ? err.message : 'Erro interno do servidor'

    logger.error({ err, req: { method: req.method, url: req.url } })

    res.status(status).json({ success: false, message, error: err.code })
}

// Erro operacional vs. programático
export class AppError extends Error {
    constructor(message, statusCode = 400, code = 'APP_ERROR') {
        super(message)
        this.statusCode  = statusCode
        this.code        = code
        this.isOperational = true
    }
}
```

### Controllers — enxutos

```javascript
// controllers/orderController.js
export class OrderController {
    constructor(orderService) {
        this.service = orderService
        // Bind para uso como callback de rota
        this.create = this.create.bind(this)
        this.findById = this.findById.bind(this)
    }

    async create(req, res, next) {
        try {
            const order = await this.service.create(req.body, req.user)
            res.status(201).json({ success: true, data: order })
        } catch (error) {
            next(error)  // sempre passar para o error handler
        }
    }
}
```

### Validação com Zod

```javascript
import { z } from 'zod'

const CreateOrderSchema = z.object({
    userId: z.string().uuid(),
    items: z.array(z.object({
        productId: z.string().uuid(),
        quantity:  z.number().int().positive(),
    })).min(1, 'Pelo menos 1 item é obrigatório'),
    discount: z.number().min(0).max(100).default(0),
})

// Middleware de validação
export function validate(schema) {
    return (req, res, next) => {
        const result = schema.safeParse(req.body)
        if (!result.success) {
            return res.status(422).json({
                success: false,
                message: 'Dados inválidos',
                errors: result.error.flatten().fieldErrors,
            })
        }
        req.body = result.data  // dados validados e transformados
        next()
    }
}

// Uso na rota
router.post('/', validate(CreateOrderSchema), controller.create)
```

### Configuração via variáveis de ambiente

```javascript
// config/index.js
const config = {
    node_env:    process.env.NODE_ENV ?? 'development',
    port:        Number(process.env.PORT ?? 3000),
    db: {
        url:     process.env.DATABASE_URL,
        pool:    Number(process.env.DB_POOL_SIZE ?? 10),
    },
    jwt: {
        secret:  process.env.JWT_SECRET,
        expires: process.env.JWT_EXPIRES_IN ?? '7d',
    },
}

// Validar variáveis obrigatórias na inicialização
const obrigatorias = ['DATABASE_URL', 'JWT_SECRET']
for (const key of obrigatorias) {
    if (!process.env[key]) throw new Error(`Variável de ambiente obrigatória ausente: ${key}`)
}

export default config
```

### Logging com Pino

```javascript
// lib/logger.js
import pino from 'pino'
import config from '../config/index.js'

const logger = pino({
    level: config.node_env === 'production' ? 'info' : 'debug',
    ...(config.node_env !== 'production' && {
        transport: { target: 'pino-pretty' }  // legível em dev
    }),
})

export default logger

// Uso
logger.info({ userId, orderId }, 'Pedido criado com sucesso')
logger.error({ err: error.message, stack: error.stack }, 'Falha ao processar')
// ✗ Nunca: console.log()
```

---

## Testes com Jest / Node Test Runner

```javascript
// tests/unit/orderService.test.js
import { describe, it, expect, beforeEach, jest } from '@jest/globals'
import { OrderService } from '../../src/services/orderService.js'

describe('OrderService', () => {
    let service
    let mockRepo

    beforeEach(() => {
        mockRepo = {
            save:      jest.fn(),
            findById:  jest.fn(),
        }
        service = new OrderService(mockRepo)
    })

    it('deve criar pedido com items válidos', async () => {
        // Arrange
        const data = { userId: 'uuid-1', items: [{ productId: 'uuid-2', quantity: 1 }] }
        mockRepo.save.mockResolvedValue({ id: 'uuid-3', ...data })

        // Act
        const result = await service.create(data)

        // Assert
        expect(result.id).toBe('uuid-3')
        expect(mockRepo.save).toHaveBeenCalledWith(data)
    })

    it('deve lançar erro quando items estiver vazio', async () => {
        await expect(service.create({ userId: 'uuid-1', items: [] }))
            .rejects.toThrow('Items são obrigatórios')
    })
})
```

---

## Armadilhas comuns

```
✗ Esquecer await → Promise não resolvida retornada como objeto
✗ try/catch vazio → erros engolidos silenciosamente
✗ Mutar objetos recebidos como parâmetro → efeitos colaterais ocultos
✗ Variáveis com var → usar sempre const/let
✗ == em vez de ===  → comparação sem coerção de tipo
✗ process.env sem fallback → crash em ambiente sem a variável
✗ Callbacks aninhados (callback hell) → usar async/await
✗ Promise sem tratamento de rejeição → UnhandledPromiseRejection
✗ console.log em produção → usar logger estruturado (pino, winston)
✗ require() em projeto com "type":"module" → usar import/export
```

### Checklist antes de todo commit

```
[ ] Sem console.log — usar logger
[ ] Sem variáveis não utilizadas
[ ] Await em todas as operações assíncronas
[ ] try/catch em todos os handlers de rota
[ ] Variáveis de ambiente validadas no startup
[ ] Testes passando: npm test
```
