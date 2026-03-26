# Skill: Stack Laravel + Vue.js + PostgreSQL
# Natural Tecnologia — nt-usina
# Arquivo: .claude/skills/stack-laravel-vue.md
#
# USO: Injetar no Coding Agent para projetos com esta stack.
# Referência rápida de padrões, convenções e armadilhas comuns.

---

## Laravel — Padrões e Convenções

### Estrutura de camadas (obrigatória)

```
Request → Controller → Service → Repository → Model → Database
                    ↓
              FormRequest (validação)
```

- **Controller:** orquestração apenas — sem lógica de negócio
- **Service:** toda a lógica de negócio — testável isoladamente
- **Repository:** acesso a dados — pode ser dispensado em projetos simples
- **Model:** atributos, relacionamentos, casts, escopos locais

### Controllers

```php
// ✓ Controller enxuto — apenas orquestra
class OrderController extends Controller
{
    public function __construct(private OrderService $service) {}

    public function store(StoreOrderRequest $request): JsonResponse
    {
        $order = $this->service->create($request->validated());
        return response()->json(['data' => OrderResource::make($order)], 201);
    }
}
```

### Form Requests — validação obrigatória

```php
class StoreOrderRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'user_id'    => ['required', 'uuid', 'exists:users,id'],
            'items'      => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'uuid', 'exists:products,id'],
            'items.*.quantity'   => ['required', 'integer', 'min:1'],
        ];
    }
}
```

### Services

```php
class OrderService
{
    public function __construct(
        private OrderRepository $orders,
        private ProductService $products,
    ) {}

    public function create(array $data): Order
    {
        // Lógica de negócio aqui
        // Lançar exceções de domínio, não HTTP exceptions
        throw new InsufficientStockException($productId);
    }
}
```

### Models

```php
class Order extends Model
{
    protected $fillable = ['user_id', 'status', 'total'];  // NUNCA usar guarded = []

    protected $casts = [
        'total'      => 'decimal:2',
        'shipped_at' => 'datetime',
        'metadata'   => 'array',
    ];

    // Relacionamentos
    public function user(): BelongsTo    { return $this->belongsTo(User::class); }
    public function items(): HasMany     { return $this->hasMany(OrderItem::class); }

    // Escopos locais
    public function scopeActive(Builder $q): Builder
    {
        return $q->where('status', '!=', 'cancelled');
    }
}
```

### Migrations

```php
// ✓ Sempre com índices nos campos de busca frequente
Schema::create('orders', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->foreignUuid('user_id')->constrained()->cascadeOnDelete();
    $table->string('status', 50)->default('pending');
    $table->decimal('total', 10, 2)->default(0);
    $table->timestamps();
    $table->softDeletes();

    $table->index('status');
    $table->index('created_at');
});
```

### API Resources — nunca retornar Model diretamente

```php
class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'status'     => $this->status,
            'total'      => $this->total,
            'created_at' => $this->created_at->toISOString(),
            'user'       => UserResource::make($this->whenLoaded('user')),
            'items'      => OrderItemResource::collection($this->whenLoaded('items')),
        ];
    }
}
```

### Resposta padrão de API

```php
// Sucesso
return response()->json(['data' => $resource], 200);

// Criação
return response()->json(['data' => $resource], 201);

// Sem conteúdo
return response()->noContent();  // 204

// Erro de validação — automático via FormRequest (422)

// Erro de negócio
return response()->json([
    'message' => 'Saldo insuficiente para esta operação.',
    'error'   => 'insufficient_balance',
], 422);
```

### Autenticação — Laravel Sanctum

```php
// Rotas protegidas
Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('orders', OrderController::class);
});

// Login
$token = $user->createToken('api-token')->plainTextToken;
```

### Tratamento global de exceções — Handler

```php
// app/Exceptions/Handler.php
public function register(): void
{
    $this->renderable(function (ModelNotFoundException $e) {
        return response()->json(['message' => 'Recurso não encontrado.'], 404);
    });

    $this->renderable(function (DomainException $e) {
        return response()->json(['message' => $e->getMessage()], 422);
    });
}
```

### Eager Loading — evitar N+1 obrigatório

```php
// ✓ Sempre carregar relacionamentos necessários
Order::with(['user', 'items.product'])->paginate(20);

// ✗ N+1 — PROIBIDO
$orders = Order::all();
foreach ($orders as $order) {
    echo $order->user->name;  // 1 query por iteração
}
```

### Testes com PHPUnit/Pest

```php
it('creates an order successfully', function () {
    $user = User::factory()->create();
    $product = Product::factory()->create(['stock' => 10]);

    $response = $this->actingAs($user)
        ->postJson('/api/v1/orders', [
            'items' => [['product_id' => $product->id, 'quantity' => 2]]
        ]);

    $response->assertStatus(201)
             ->assertJsonPath('data.status', 'pending');

    $this->assertDatabaseHas('orders', ['user_id' => $user->id]);
});
```

---

## Vue.js 3 — Padrões e Convenções

### Composition API (obrigatório — não usar Options API)

```javascript
// ✓ Script Setup
<script setup>
import { ref, computed, onMounted } from 'vue'
import { useOrderStore } from '@/stores/orderStore'

const store = useOrderStore()
const isLoading = ref(false)
const orders = computed(() => store.orders)

onMounted(() => store.fetchOrders())
</script>
```

### Pinia — gerenciamento de estado

```javascript
// stores/orderStore.js
import { defineStore } from 'pinia'
import { orderApi } from '@/services/orderApi'

export const useOrderStore = defineStore('orders', {
    state: () => ({ orders: [], loading: false, error: null }),

    getters: {
        activeOrders: (state) => state.orders.filter(o => o.status !== 'cancelled'),
    },

    actions: {
        async fetchOrders() {
            this.loading = true
            try {
                this.orders = await orderApi.list()
            } catch (e) {
                this.error = e.message
            } finally {
                this.loading = false
            }
        },
    },
})
```

### Serviços de API — camada isolada

```javascript
// services/orderApi.js
import axios from '@/lib/axios'

export const orderApi = {
    list: ()           => axios.get('/orders').then(r => r.data.data),
    create: (data)     => axios.post('/orders', data).then(r => r.data.data),
    findById: (id)     => axios.get(`/orders/${id}`).then(r => r.data.data),
}
```

### Componentes — regras

```
✓ Nome em PascalCase: OrderCard.vue, UserForm.vue
✓ Componentes pequenos: máximo 150 linhas no template
✓ Props tipadas com defineProps<{}>()
✓ Emits declarados com defineEmits<{}>()
✓ Sem lógica de negócio em componentes — usar stores e composables
✓ Composables para lógica reutilizável: useAuth(), usePagination()
```

---

## PostgreSQL — Boas Práticas

```sql
-- ✓ UUID como PK (padrão do projeto)
id UUID PRIMARY KEY DEFAULT gen_random_uuid()

-- ✓ Índices para campos de busca frequente
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);

-- ✓ Índice composto quando busca usa múltiplos campos juntos
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- ✓ Soft delete — nunca deletar registros críticos
deleted_at TIMESTAMP NULL DEFAULT NULL

-- ✓ Timestamps padrão
created_at TIMESTAMP NOT NULL DEFAULT NOW(),
updated_at TIMESTAMP NOT NULL DEFAULT NOW()
```

### Armadilhas comuns

```
✗ LIKE '%termo%'  → não usa índice — usar full text search para buscas textuais
✓ LIKE 'termo%'   → usa índice

✗ N+1 queries — sempre usar JOINs ou Eager Loading
✓ EXPLAIN ANALYZE em queries lentas durante desenvolvimento

✗ SELECT * em queries de produção
✓ Selecionar apenas colunas necessárias
```

---

## Armadilhas comuns desta stack

```
✗ Retornar Model diretamente na API    → usar API Resource
✗ Lógica no Controller                 → mover para Service
✗ Acessar DB no Controller             → usar Service/Repository
✗ Options API no Vue 3                 → usar Composition API
✗ this.$store (Vuex)                   → usar Pinia
✗ Mutação direta de state no Pinia     → usar actions
✗ Migrations com ALTER TABLE em prod   → sempre nova migration
✗ Esquecer ->validated() no Controller → nunca usar $request->all()
```
