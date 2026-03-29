# 08 — db.rs: PostgreSQL Connection Pool

## What we built

`src/db.rs` creates a PostgreSQL connection pool that the entire app shares. It is called once at startup in `main.rs` and the pool is passed into every route handler that needs the database.

---

## The Code

```rust
use sqlx::postgres::{PgPool, PgPoolOptions};

pub async fn create_pool(database_url: &str) -> PgPool {
    PgPoolOptions::new()
        .max_connections(10)
        .connect(database_url)
        .await
        .expect("Failed to connect to PostgreSQL")
}
```

---

## Why a Connection Pool?

Opening a database connection is expensive:
- TCP handshake between server and PostgreSQL
- Authentication (check credentials)
- Memory allocated on both sides
- Takes 10-50ms every time

Without a pool, 1000 simultaneous requests = 1000 connections = PostgreSQL crashes.

With a pool of 10 connections:
- Connections are opened ONCE at startup
- Each request borrows one connection for 1-5ms then returns it
- 10 connections handles hundreds of requests per second comfortably

---

## How it connects to main.rs

```rust
mod db;

let _pool = db::create_pool(&config.database_url).await;
```

The `_` prefix silences the unused variable warning while the pool isn't yet wired into Axum state. Once state is added it becomes `pool` and gets passed to every handler.

---

## Key Concepts

| Concept | What it means |
|---|---|
| `PgPool` | A managed set of PostgreSQL connections shared across the app |
| `max_connections(10)` | Maximum simultaneous DB connections — tune based on load |
| `.expect()` | Like `.unwrap()` but with a custom panic message for easier debugging |
| `&str` parameter | Borrows the string — doesn't take ownership of it |
| `pub async fn` | Public async function — callable from main.rs |
