## Question
Right now `main.rs` creates the config and pool but the route handlers can't access them. If a handler needs to query the database, how do you think it should get access to the pool?

## My Answers
First guess: "send a post request"
Second guess: "you make it available in the file that the handler is in so it can access it"

## Full Explanation
A POST request is something a client sends from outside — not how internal code shares data.

Making it available in the file is the right direction, but you can't just import it because the pool is created at RUNTIME with real database credentials, not at compile time.

The solution is Axum's **State** system.

In `main.rs` you attach shared data to the router:
```rust
let app = Router::new()
    .route("/health", get(handler))
    .with_state(pool);
```

Then any handler that needs it declares a `State` parameter:
```rust
async fn handler(State(pool): State<PgPool>) -> ... {
    // pool is available here automatically
}
```

Axum sees `State(pool)` in the handler signature and automatically injects the data on every request. You never pass it manually.

Since we need both the pool AND config (for JWT secret etc.) in handlers, we create one `AppState` struct that holds everything:

```rust
pub struct AppState {
    pub pool: PgPool,
    pub config: Config,
}
```

This gets attached to the router once in `main.rs` and is available in any handler that asks for it via `State(state): State<AppState>`.

## Key concept
Axum uses **extractors** — special parameter types that Axum knows how to automatically inject into handlers. `State` is one extractor. Later you'll use `Path`, `Json`, `Extension` and others — all work the same way.
