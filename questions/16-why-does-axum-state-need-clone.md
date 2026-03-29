## Question
Axum requires state to implement `Clone`. Why do you think Axum needs to clone the state for every request?

## Answer
"cause it needs to share the state with multiple requests, if not cloned it will be owned by just one"

## Full Explanation
Exactly right. Rust's ownership rules mean only one thing can own a value at a time. If Axum gave the state to request 1, request 2 couldn't use it — the value would be moved.

Cloning solves this — each request gets its own clone of the state. But importantly, cloning `PgPool` doesn't create new database connections. It copies a reference-counted pointer to the same underlying pool. All clones share the same 10 connections.

The fix was adding `#[derive(Clone)]` to both structs:

```rust
// state.rs
#[derive(Clone)]
pub struct AppState {
    pub config: Config,
    pub db_pool: PgPool,
}

// config.rs
#[derive(Clone)]
pub struct Config { ... }
```

`#[derive(Clone)]` is a macro that automatically generates a `clone()` method for your struct by cloning each field individually.

Axum's requirement: `S: Clone + Send + Sync + 'static`
- `Clone` — can be cloned per request
- `Send` — can be sent across threads
- `Sync` — can be shared between threads safely
- `'static` — doesn't contain any short-lived references
