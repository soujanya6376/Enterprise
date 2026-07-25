# Implementation Roadmap

A phased plan. Each phase is independently shippable and testable.

## Phase 0 — Foundations  ✅ (scaffolded here)
- Monorepo layout, docs (architecture, ERD, API), Docker compose.
- Backend bootstrap: Nest config, global pipes/filters/interceptors, Swagger, `/api/v1`.
- Prisma schema for all entities + migration + seed (roles, admin, global tax).

## Phase 1 — Auth & Users
- JWT access/refresh, bcrypt hashing, `JwtAuthGuard`, `RolesGuard`.
- Login / refresh / logout / me; admin user CRUD + password reset.
- Unit tests: auth service, roles guard.

## Phase 2 — Products & Tax
- Product CRUD, activate/deactivate, search/filter, soft delete.
- Image upload via storage abstraction (local).
- Excel import: validation, error report, bulk insert, skip duplicates, summary.
- Global tax setting + per-product override; tax resolution.

## Phase 3 — Billing, Orders & Payments
- Order creation with authoritative server-side calculation + invoice number.
- Order history, search, detail.
- Payments (cash/UPI/credit/debit), status transitions, refund.
- Unit tests: calculation engine, tax snapshot, status transitions.

## Phase 4 — Invoice & Printing
- Thermal 80mm HTML template + A4 PDF (Puppeteer/pdf lib).
- Reprint endpoints.

## Phase 5 — Reports & Dashboard
- Today/monthly revenue + tax, top products, recent orders.

## Phase 6 — Flutter client
- Core: theme (light/dark), Dio + auth interceptor, GoRouter guards, Hive session.
- Auth screens → Admin (dashboard, products, tax, users, reports) → Cashier
  (billing, order history). Responsive web + mobile, loading/error states.

## Phase 7 — Hardening
- E2E tests, rate limiting, refresh-token rotation, audit log coverage,
  S3 storage implementation, CI/CD, observability.

## Suggested order of work
1. `npm install` backend → `prisma migrate dev` → `npm run seed`.
2. Verify Swagger at `/api/docs`, log in as admin.
3. Build out frontend feature-by-feature against the running API.
