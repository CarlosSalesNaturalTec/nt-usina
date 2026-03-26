# Skill: Google Cloud Platform (GCP)
# Natural Tecnologia — nt-usina
# Arquivo: .claude/skills/stack-gcp.md
#
# USO: Injetar no Coding Agent e Deploy Agent para projetos com infraestrutura GCP.

---

## Serviços mais usados — referência rápida

| Serviço | Para que serve | Quando usar |
|---|---|---|
| Cloud Run | Containers serverless | API, backend, workers stateless |
| Cloud SQL | PostgreSQL/MySQL gerenciado | Banco de dados relacional |
| Cloud Storage | Armazenamento de objetos | Arquivos, uploads, assets |
| Pub/Sub | Mensageria assíncrona | Comunicação entre serviços, eventos |
| Secret Manager | Secrets e variáveis sensíveis | Nunca usar env vars diretas em produção |
| Cloud Build | CI/CD | Build e deploy automático |
| Artifact Registry | Registro de containers | Imagens Docker |
| Cloud Functions | Funções serverless | Webhooks, triggers pontuais |
| Firestore | NoSQL documento | Dados não relacionais, tempo real |
| BigQuery | Data warehouse | Analytics, relatórios complexos |

---

## Cloud Run — Padrões

### Dockerfile padrão (Laravel)

```dockerfile
FROM php:8.3-fpm-alpine

WORKDIR /var/www/html

RUN apk add --no-cache nginx postgresql-dev \
    && docker-php-ext-install pdo pdo_pgsql opcache

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY . .

RUN composer install --no-dev --optimize-autoloader \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

EXPOSE 8080
CMD ["php-fpm"]
```

### Deploy via gcloud (PowerShell)

```powershell
# Build e push
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME

# Deploy
gcloud run deploy $SERVICE_NAME `
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME `
  --platform managed `
  --region $REGION `
  --set-secrets="APP_KEY=app-key:latest,DB_PASSWORD=db-password:latest" `
  --set-env-vars="APP_ENV=production,LOG_CHANNEL=stderr" `
  --min-instances=0 `
  --max-instances=10 `
  --memory=512Mi `
  --cpu=1 `
  --port=8080 `
  --allow-unauthenticated   # remover para APIs privadas
```

### Variáveis de ambiente — nunca hardcoded

```powershell
# ✓ Sempre via Secret Manager
--set-secrets="NOME_VAR=nome-do-secret:latest"

# ✗ Nunca diretamente
--set-env-vars="DB_PASSWORD=senha123"  # PROIBIDO
```

---

## Secret Manager

```powershell
# Criar secret
gcloud secrets create nome-do-secret --replication-policy="automatic"

# Adicionar valor
echo -n "valor-do-secret" | gcloud secrets versions add nome-do-secret --data-file=-

# Conceder acesso ao service account do Cloud Run
gcloud secrets add-iam-policy-binding nome-do-secret `
  --member="serviceAccount:$SA_EMAIL" `
  --role="roles/secretmanager.secretAccessor"
```

### Acessar no código (Laravel)

```php
// Configurar no .env de produção via Cloud Run --set-secrets
// O Secret Manager injeta como variável de ambiente automaticamente
$valor = env('NOME_VAR');
```

---

## Cloud SQL

```powershell
# Criar instância PostgreSQL
gcloud sql instances create nome-instancia `
  --database-version=POSTGRES_16 `
  --tier=db-f1-micro `
  --region=$REGION `
  --storage-type=SSD `
  --storage-size=10GB

# Criar banco e usuário
gcloud sql databases create nome-banco --instance=nome-instancia
gcloud sql users create nome-usuario --instance=nome-instancia --password=SENHA

# Conexão do Cloud Run via Cloud SQL Auth Proxy (automático)
# Usar connection name no DATABASE_URL:
# postgresql://user:pass@localhost/dbname?host=/cloudsql/PROJECT:REGION:INSTANCE
```

---

## Cloud Storage

```php
// Laravel — via league/flysystem-google-cloud-storage
// config/filesystems.php
'gcs' => [
    'driver'         => 'gcs',
    'project_id'     => env('GOOGLE_CLOUD_PROJECT_ID'),
    'key_file_path'  => env('GOOGLE_APPLICATION_CREDENTIALS'),
    'bucket'         => env('GCS_BUCKET'),
    'path_prefix'    => env('GCS_PATH_PREFIX', ''),
    'visibility'     => 'public',
],

// Uso
Storage::disk('gcs')->put('uploads/arquivo.pdf', $conteudo);
$url = Storage::disk('gcs')->url('uploads/arquivo.pdf');
```

---

## Pub/Sub

```python
# Publisher (Python)
from google.cloud import pubsub_v1

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(PROJECT_ID, TOPIC_NAME)

data = json.dumps({"evento": "pedido_criado", "id": order_id}).encode("utf-8")
future = publisher.publish(topic_path, data)
future.result()  # aguardar confirmação

# Subscriber (Python)
subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path(PROJECT_ID, SUBSCRIPTION_NAME)

def callback(message: pubsub_v1.subscriber.message.Message) -> None:
    data = json.loads(message.data.decode("utf-8"))
    # processar...
    message.ack()

streaming_pull_future = subscriber.subscribe(subscription_path, callback=callback)
```

---

## IAM — Princípio do menor privilégio

```powershell
# Criar Service Account dedicado por serviço
gcloud iam service-accounts create sa-nome-servico `
  --display-name="SA Nome Servico"

# Conceder apenas as permissões necessárias
gcloud projects add-iam-policy-binding $PROJECT_ID `
  --member="serviceAccount:sa-nome-servico@$PROJECT_ID.iam.gserviceaccount.com" `
  --role="roles/cloudsql.client"

# Regras:
# ✗ Nunca usar roles/owner ou roles/editor em produção
# ✓ Sempre usar roles específicos e mínimos
# ✓ Service Account por serviço — nunca compartilhar
```

---

## Logging — padrão para Cloud Run

```php
// Laravel — logar para stderr (capturado pelo Cloud Logging)
// config/logging.php
'channels' => [
    'stderr' => [
        'driver'  => 'monolog',
        'handler' => StreamHandler::class,
        'with'    => ['stream' => 'php://stderr'],
        'level'   => 'debug',
    ],
],

// Log estruturado (JSON) para facilitar queries no Cloud Logging
Log::info('Pedido criado', ['order_id' => $id, 'user_id' => $userId]);
```

---

## Armadilhas comuns

```
✗ Credenciais hardcoded no código           → usar Secret Manager
✗ Service Account com permissões excessivas → princípio do menor privilégio
✗ Imagem Docker sem .dockerignore           → incluir vendor/, node_modules/, .env
✗ Cloud Run sem min-instances=0 em dev     → custo desnecessário
✗ Cloud SQL exposta publicamente            → usar Cloud SQL Auth Proxy
✗ Logs com dados sensíveis                  → nunca logar tokens, senhas, CPF
✗ Timeout do Cloud Run padrão (5min)        → ajustar para jobs longos
```

### .dockerignore obrigatório

```
.git
.env
.env.*
vendor/
node_modules/
storage/logs/
tests/
*.md
.claude/
docs/
backlog/
```
