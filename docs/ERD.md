# Entity Relationship Diagram

```mermaid
erDiagram
    ROLE ||--o{ USER : has
    USER ||--o{ ORDER : creates
    USER ||--o{ PRODUCT_IMPORT_LOG : performs
    USER ||--o{ AUDIT_LOG : actor
    PRODUCT ||--o{ ORDER_ITEM : "appears in"
    ORDER ||--o{ ORDER_ITEM : contains
    ORDER ||--o{ PAYMENT : "paid by"

    ROLE {
        uuid id PK
        string name UK "ADMIN | USER"
        string description
        datetime createdAt
    }

    USER {
        uuid id PK
        string username UK
        string email UK
        string passwordHash
        uuid roleId FK
        boolean isActive
        int tokenVersion "refresh revocation"
        datetime createdAt
        datetime updatedAt
        datetime deletedAt "soft delete"
    }

    PRODUCT {
        uuid id PK
        string name
        string description
        decimal price "12,2"
        decimal taxPercentage "nullable -> use global"
        string imageUrl
        boolean isActive
        datetime createdAt
        datetime updatedAt
        datetime deletedAt "soft delete"
    }

    GLOBAL_TAX_SETTING {
        uuid id PK
        decimal percentage
        boolean isActive
        datetime createdAt
        datetime updatedAt
    }

    ORDER {
        uuid id PK
        string invoiceNumber UK
        uuid cashierId FK
        decimal subtotal
        decimal taxAmount
        decimal grandTotal
        string status "PENDING|PAID|PARTIALLY_PAID|REFUNDED"
        datetime createdAt
        datetime updatedAt
    }

    ORDER_ITEM {
        uuid id PK
        uuid orderId FK
        uuid productId FK
        string productName "snapshot"
        decimal price "snapshot"
        int quantity
        decimal taxPercentage "snapshot"
        decimal taxAmount
        decimal lineTotal
    }

    PAYMENT {
        uuid id PK
        uuid orderId FK
        decimal amount
        string paymentMethod "CASH|UPI|CREDIT_CARD|DEBIT_CARD"
        string status "PENDING|PAID|PARTIALLY_PAID|REFUNDED"
        datetime createdAt
    }

    PRODUCT_IMPORT_LOG {
        uuid id PK
        uuid uploadedById FK
        string fileName
        int totalRows
        int insertedRows
        int skippedRows
        int failedRows
        json errors
        datetime createdAt
    }

    AUDIT_LOG {
        uuid id PK
        uuid actorId FK
        string action
        string entity
        string entityId
        json metadata
        datetime createdAt
    }
```

## Notes

- **UUID** primary keys everywhere (`@default(uuid())`).
- **Soft deletes** on `users` and `products` via `deletedAt`; queries filter
  `deletedAt: null`.
- **Snapshots** in `order_items` (name, price, taxPercentage) keep historical
  invoices stable when products/tax later change.
- **Indexes**: `product.name`, `product.isActive`, `order.invoiceNumber` (unique),
  `order.createdAt`, `order.cashierId`, `order_item.orderId`, `payment.orderId`,
  `user.username`/`email` (unique).
