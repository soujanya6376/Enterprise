# System Architecture

## 1. Overview

The system is a two-tier client/server application:

```
┌─────────────────────────────┐         ┌──────────────────────────────┐
│        Flutter Client        │  HTTPS  │         NestJS API            │
│  (Web / Android / iOS)       │ ◄─────► │   /api/v1  (REST + Swagger)   │
│  Riverpod · Dio · GoRouter   │  JWT    │   Guards · Interceptors · DTO │
│  Hive (token + offline cache)│         │   Prisma ──► PostgreSQL       │
└─────────────────────────────┘         │   Local FS (uploads, S3-ready)│
                                         └──────────────────────────────┘
```

Both clients share a single Flutter codebase. All money math (subtotal, tax,
grand total) is performed **server-side** so every platform shows identical
totals and the client cannot tamper with pricing.

## 2. Backend — Clean Architecture / feature modules

Each feature is a self-contained NestJS module following the same layering:

```
module/
├── dto/                 # request/response shapes + class-validator rules
├── entities/            # Swagger response models
├── <feature>.controller.ts   # HTTP layer (routing, guards, Swagger)
├── <feature>.service.ts      # business logic (use-cases)
├── <feature>.repository.ts   # data access (Prisma) — Repository Pattern
└── <feature>.module.ts       # DI wiring
```

Cross-cutting concerns live in `src/common`:

- **Guards** — `JwtAuthGuard`, `RolesGuard` (role-based authorization).
- **Decorators** — `@Roles()`, `@CurrentUser()`, `@Public()`.
- **Interceptors** — `LoggingInterceptor` (request/response + timing), `TransformInterceptor` (uniform envelope).
- **Filters** — `AllExceptionsFilter` (consistent error payloads).
- **Pipes** — global `ValidationPipe` (whitelist + transform).
- **Pagination** — shared `PaginationDto` + `paginate()` helper.

### Modules

| Module | Responsibility |
|--------|----------------|
| `auth` | Login, refresh, logout, password reset, JWT issuing |
| `users` | Admin CRUD over users, role assignment, password reset |
| `products` | CRUD, activate/deactivate, image upload, Excel import, search/filter |
| `tax` | Global tax setting + per-product override; tax resolution logic |
| `orders` | Cart → order creation, server-side calculation, history, reprint |
| `payments` | Record payments, payment status transitions |
| `reports` | Today / monthly revenue + tax, top products, recent orders |
| `uploads` | File storage abstraction (local now, S3 later) |
| `invoice` | Thermal (80mm HTML) + A4 PDF generation |

### Storage abstraction

`StorageService` is an interface with a `LocalStorageService` implementation
writing to `./uploads`. Swapping to S3 means providing an `S3StorageService`
with the same interface and changing one provider binding — no call-site changes.

## 3. Tax resolution

```
resolveTaxPercentage(product):
    if product.taxPercentage is not null  → use product.taxPercentage
    else                                  → use active GlobalTaxSetting.percentage
```

Resolution happens at **order time** and the resolved rate is snapshotted into
`order_items.taxPercentage`, so historical invoices never change if tax config
later changes.

## 4. Bill calculation (server-side, authoritative)

For each cart line:

```
lineSubtotal = price × quantity
taxAmount    = round(lineSubtotal × taxPercentage / 100)
lineTotal    = lineSubtotal + taxAmount
```

Order totals:

```
subtotal   = Σ lineSubtotal
taxAmount  = Σ taxAmount
grandTotal = subtotal + taxAmount
```

Monetary values are stored as `Decimal(12,2)`. Rounding is half-up to 2 dp.

## 5. Authentication flow

```
1. POST /auth/login {username, password}
   → verify bcrypt hash → issue accessToken (15m) + refreshToken (7d)
2. Client stores tokens in Hive; attaches `Authorization: Bearer <access>`.
3. On 401 → POST /auth/refresh {refreshToken} → new access token.
4. RolesGuard checks @Roles('ADMIN') metadata against JWT role claim.
5. POST /auth/logout → refresh token revoked (tokenVersion bump).
6. Admin password reset: PATCH /users/:id/reset-password (ADMIN only).
```

## 6. Invoice generation workflow

```
Order created (status=PENDING)
        │
   Payment recorded ──► if amount == grandTotal → order.status = PAID
        │                       partial          → PARTIALLY_PAID
        ▼
Invoice available:
   GET /invoice/:orderId/thermal  → printer-friendly 80mm HTML
   GET /invoice/:orderId/pdf      → A4 PDF (download)
Reprint: same endpoints, idempotent.
```

## 7. Non-functional

- SOLID, Repository Pattern, DI throughout.
- API versioning via URI (`/api/v1`).
- Environment-based config via `@nestjs/config` + `.env`.
- Docker + docker-compose for Postgres and the API.
- Unit tests for services (calculation, tax resolution, auth).
- Logging interceptor + structured error filter.

## 8. Frontend architecture

```
lib/
├── core/          # config, theme, dio client, router, error, storage, widgets
└── features/
    ├── auth/       data│domain│presentation
    ├── products/
    ├── billing/
    ├── orders/
    └── reports/
```

Each feature uses the data → domain → presentation split. Riverpod providers
expose state notifiers; Dio handles networking with an auth interceptor that
injects the token and refreshes on 401; GoRouter guards routes by auth + role;
Hive persists the session and a lightweight product cache for offline billing.
