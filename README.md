# POS Billing Application

A production-ready, cross-platform Point of Sale (POS) billing system.

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Web / Android / iOS) |
| Backend | NestJS (REST, versioned `/api/v1`) |
| Database | PostgreSQL |
| ORM | Prisma |
| Auth | JWT (access + refresh), role-based |
| State mgmt | Riverpod |
| Networking | Dio |
| Routing | GoRouter |
| Local storage | Hive |
| Storage | Local filesystem (S3-swappable) |
| API docs | Swagger (`/api/docs`) |

## Repository layout

```
Billing App/
├── backend/            # NestJS API + Prisma
├── frontend/           # Flutter app (single codebase)
├── docs/               # Architecture, ERD, API spec, roadmap
└── docker-compose.yml  # Postgres + backend
```

## Quick start (backend)

```bash
cd backend
cp .env.example .env          # adjust DATABASE_URL / JWT secrets
npm install
npx prisma migrate dev --name init
npm run seed                  # creates roles + default admin + global tax
npm run start:dev             # http://localhost:3000/api/v1, docs at /api/docs
```

Default admin after seeding: **admin / Admin@123** (change immediately).

## Quick start (with Docker)

```bash
docker compose up --build     # starts Postgres + backend
```

## Quick start (frontend)

```bash
cd frontend
flutter pub get
flutter run -d chrome         # web; or -d android / -d ios
```

Set the API base URL in `frontend/lib/core/config/app_config.dart`.

## Roles

- **Admin** — products, tax config, users, reports (full access).
- **Cashier (User)** — billing, payments, invoice printing, order history.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full design, [`docs/ERD.md`](docs/ERD.md) for the data model, [`docs/API.md`](docs/API.md) for endpoints, and [`docs/ROADMAP.md`](docs/ROADMAP.md) for the phased implementation plan.
