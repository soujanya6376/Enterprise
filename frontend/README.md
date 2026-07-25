# POS Billing — Flutter Client

Single codebase for Web, Android and iOS.

## Setup

```bash
flutter pub get
# Web (point at your running backend):
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
# Android emulator (use 10.0.2.2 for host loopback):
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

Default credentials after backend seed: **admin / Admin@123**.

## Structure

```
lib/
├── core/
│   ├── config/        app_config.dart        (API base URL)
│   ├── network/       dio_client.dart         (auth + 401 refresh)
│   ├── router/        app_router.dart         (GoRouter, role guards)
│   ├── storage/       session_store.dart      (Hive session)
│   ├── theme/         app_theme.dart          (light/dark)
│   └── providers.dart                         (Riverpod DI)
└── features/
    ├── auth/          login + auth controller
    ├── admin/         admin shell (nav)
    ├── products/      product list + form
    ├── tax/           global tax settings
    ├── users/         user list + create
    ├── billing/       product grid, cart, payment dialog
    ├── orders/        order history + reprint
    └── reports/       admin dashboard
```

State: Riverpod · Networking: Dio · Routing: GoRouter · Local storage: Hive.
All totals are computed by the backend; the cart shows a client-side estimate only.

> Run `flutter create .` once in this folder to generate the platform runners
> (android/, ios/, web/) if they are not present.
