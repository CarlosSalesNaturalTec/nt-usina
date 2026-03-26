# Skill: Stack Python + FastAPI
# Natural Tecnologia — nt-usina
# Arquivo: .claude/skills/stack-python.md
#
# USO: Injetar no Coding Agent para projetos Python/FastAPI.

---

## Estrutura de projeto FastAPI

```
app/
├── main.py                  # Entrypoint — instância FastAPI, routers, middleware
├── core/
│   ├── config.py            # Settings via pydantic-settings
│   ├── security.py          # JWT, hashing, dependências de auth
│   └── database.py          # Engine, SessionLocal, Base
├── api/
│   └── v1/
│       ├── router.py        # Agrega todos os routers da v1
│       └── endpoints/
│           ├── auth.py
│           └── orders.py
├── models/                  # SQLAlchemy ORM models
├── schemas/                 # Pydantic schemas (request/response)
├── services/                # Lógica de negócio
├── repositories/            # Acesso a dados
└── tests/
    ├── conftest.py
    └── test_orders.py
```

---

## FastAPI — Padrões

### main.py

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.router import api_router
from app.core.config import settings

app = FastAPI(title=settings.PROJECT_NAME, version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")
```

### Configurações via pydantic-settings

```python
# core/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "nt-usina"
    DATABASE_URL: str
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    class Config:
        env_file = ".env"

settings = Settings()
```

### Schemas — Pydantic v2

```python
from pydantic import BaseModel, UUID4, field_validator
from datetime import datetime
from typing import Optional

class OrderCreate(BaseModel):
    user_id: UUID4
    items: list[OrderItemCreate]

    @field_validator('items')
    @classmethod
    def items_not_empty(cls, v):
        if not v:
            raise ValueError('Pelo menos 1 item é obrigatório')
        return v

class OrderResponse(BaseModel):
    id: UUID4
    status: str
    total: float
    created_at: datetime

    model_config = {"from_attributes": True}  # permite criar de ORM model
```

### Endpoints — Dependency Injection

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import get_current_user

router = APIRouter(prefix="/orders", tags=["orders"])

@router.post("/", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def create_order(
    order_in: OrderCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    service: OrderService = Depends(get_order_service),
):
    return service.create(db=db, data=order_in, user=current_user)
```

### Services — lógica de negócio

```python
class OrderService:
    def __init__(self, repo: OrderRepository):
        self.repo = repo

    def create(self, db: Session, data: OrderCreate, user: User) -> Order:
        # Validação de negócio
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Usuário inativo não pode criar pedidos"
            )
        return self.repo.create(db=db, data=data)

def get_order_service(db: Session = Depends(get_db)) -> OrderService:
    return OrderService(repo=OrderRepository())
```

### SQLAlchemy Models

```python
from sqlalchemy import Column, String, Numeric, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base
import uuid
from datetime import datetime

class Order(Base):
    __tablename__ = "orders"

    id         = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id    = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    status     = Column(String(50), nullable=False, default="pending")
    total      = Column(Numeric(10, 2), nullable=False, default=0)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    user  = relationship("User", back_populates="orders")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
```

### Migrations — Alembic

```bash
# Criar migration
alembic revision --autogenerate -m "create_orders_table"

# Aplicar
alembic upgrade head

# Rollback
alembic downgrade -1
```

### Testes com pytest

```python
# tests/conftest.py
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.core.database import get_db, Base

SQLALCHEMY_TEST_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_TEST_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(bind=engine)

@pytest.fixture
def client():
    Base.metadata.create_all(bind=engine)
    def override_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()
    app.dependency_overrides[get_db] = override_db
    yield TestClient(app)
    Base.metadata.drop_all(bind=engine)

# tests/test_orders.py
def test_create_order(client, auth_headers):
    response = client.post("/api/v1/orders", json={...}, headers=auth_headers)
    assert response.status_code == 201
    assert response.json()["status"] == "pending"
```

---

## Tratamento de erros

```python
# Handler global — main.py
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

@app.exception_handler(RequestValidationError)
async def validation_handler(request, exc):
    return JSONResponse(
        status_code=422,
        content={"message": "Dados inválidos", "errors": exc.errors()}
    )

# Exceções de domínio
class DomainException(HTTPException):
    def __init__(self, detail: str):
        super().__init__(status_code=422, detail=detail)

# Uso no service
raise DomainException("Saldo insuficiente para esta operação")
```

---

## Armadilhas comuns

```
✗ Importar settings no topo do módulo     → lazy import ou usar Depends()
✗ Session do DB sem fechar                → sempre usar try/finally ou context manager
✗ Validação apenas no schema              → validar regras de negócio no service
✗ Retornar ORM model diretamente          → sempre passar por schema Pydantic
✗ Sync code em endpoint async             → usar run_in_executor para I/O bloqueante
✗ Secrets no .env commitado               → .env no .gitignore, usar Secret Manager
✗ print() para debug                      → usar logging estruturado
```

### requirements.txt essenciais

```
fastapi>=0.111.0
uvicorn[standard]>=0.29.0
pydantic>=2.7.0
pydantic-settings>=2.2.0
sqlalchemy>=2.0.0
alembic>=1.13.0
psycopg2-binary>=2.9.9
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
python-multipart>=0.0.9
pytest>=8.0.0
httpx>=0.27.0
```
