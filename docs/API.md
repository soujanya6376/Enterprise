# API Specification

Base URL: `/api/v1` · Auth: `Authorization: Bearer <accessToken>` · Docs: `/api/docs`

All list endpoints accept `?page=1&limit=20&search=<q>` and return:

```json
{ "data": [ ... ], "meta": { "page": 1, "limit": 20, "total": 0, "totalPages": 0 } }
```

## Auth
| Method | Path | Role | Body / Notes |
|--------|------|------|--------------|
| POST | `/auth/login` | public | `{ username, password }` → `{ accessToken, refreshToken, user }` |
| POST | `/auth/refresh` | public | `{ refreshToken }` → `{ accessToken }` |
| POST | `/auth/logout` | auth | revokes refresh tokens |
| GET  | `/auth/me` | auth | current user profile |

## Users (ADMIN)
| Method | Path | Body |
|--------|------|------|
| GET | `/users` | list (paginated, search) |
| POST | `/users` | `{ username, email, password, roleName }` |
| GET | `/users/:id` | |
| PATCH | `/users/:id` | `{ email?, isActive?, roleName? }` |
| PATCH | `/users/:id/reset-password` | `{ newPassword }` |
| DELETE | `/users/:id` | soft delete |

## Products
| Method | Path | Role | Notes |
|--------|------|------|-------|
| GET | `/products` | auth | search, `?isActive=`, paginated |
| GET | `/products/:id` | auth | |
| POST | `/products` | ADMIN | `{ name, description?, price, taxPercentage? }` |
| PATCH | `/products/:id` | ADMIN | partial update |
| PATCH | `/products/:id/status` | ADMIN | `{ isActive }` |
| DELETE | `/products/:id` | ADMIN | soft delete |
| POST | `/products/:id/image` | ADMIN | multipart `file` |
| POST | `/products/import` | ADMIN | multipart `.xlsx` → import summary |
| GET | `/products/import/template` | ADMIN | downloadable template |

## Tax
| Method | Path | Role | Notes |
|--------|------|------|-------|
| GET | `/tax/global` | auth | active global tax |
| PUT | `/tax/global` | ADMIN | `{ percentage }` |
| PATCH | `/tax/products/:id` | ADMIN | `{ taxPercentage|null }` override |

## Orders
| Method | Path | Role | Notes |
|--------|------|------|-------|
| POST | `/orders` | auth | `{ items:[{productId, quantity}] }` — totals computed server-side |
| GET | `/orders` | auth | search by invoiceNumber, date range, paginated |
| GET | `/orders/:id` | auth | full detail incl. items + payments |

## Payments
| Method | Path | Role | Notes |
|--------|------|------|-------|
| POST | `/payments` | auth | `{ orderId, amount, paymentMethod }` → updates order status |
| GET | `/payments/order/:orderId` | auth | payments for an order |
| POST | `/payments/:id/refund` | ADMIN | mark refunded |

## Invoice
| Method | Path | Role | Notes |
|--------|------|------|-------|
| GET | `/invoice/:orderId/thermal` | auth | 80mm printer-friendly HTML |
| GET | `/invoice/:orderId/pdf` | auth | A4 PDF download |

## Reports (ADMIN)
| Method | Path | Notes |
|--------|------|-------|
| GET | `/reports/dashboard` | today orders/revenue/tax, monthly revenue/tax |
| GET | `/reports/top-products?limit=10` | top selling products |
| GET | `/reports/recent-orders?limit=10` | recent orders |

## Error envelope
```json
{ "statusCode": 400, "message": "…", "error": "Bad Request", "path": "/api/v1/…", "timestamp": "…" }
```
