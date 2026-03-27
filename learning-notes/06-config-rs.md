# 06 — config.rs: Loading Environment Variables in Rust

## What we built

`src/config.rs` is a single struct called `Config` that reads every environment variable the app needs when it first starts up.

---

## The struct

```rust
pub struct Config {
    pub port: u32,
    pub database_url: String,
    pub jwt_secret: String,
    pub redis_url: String,
}
```

Each field maps directly to one environment variable. The types matter:

- `port` is a `u32` (an unsigned 32-bit integer) — not a `String`. We parse it from the raw string the OS gives us.
- The rest are `String` because connection strings and secrets are just text.

---

## The `from_env()` method

This is the only way to build a `Config`. It reads env vars using `std::env::var()` and returns `Result<Self, String>` — meaning it either succeeds with a fully built `Config`, or fails with an error message explaining what went wrong.

### Optional field (port)

```rust
port: var("PORT")
    .unwrap_or_else(|_| "8080".to_string())
    .parse()
    .map_err(|_| "PORT must be a number".to_string())?
```

- `var("PORT")` returns `Result<String, VarError>` — it fails if the variable is not set.
- `.unwrap_or_else(|_| "8080".to_string())` — if PORT is missing, use "8080" as the default instead of failing.
- `.parse()` — convert the string "8080" into the number `8080`. This can fail if someone sets PORT to "abc".
- `.map_err(...)` — if `.parse()` fails, replace the generic error with a human-readable message.
- `?` — if anything went wrong, return the error immediately from `from_env()`.

### Required fields (database_url, jwt_secret, redis_url)

```rust
database_url: var("DATABASE_URL")
    .map_err(|_| "DATABASE_URL is required".to_string())?
```

Simpler — no default. If the variable is missing, fail immediately with a clear message. The app should not start without a database.

---

## Why one struct instead of calling `var()` everywhere?

If you called `std::env::var("JWT_SECRET")` inside a handler or service, you would have two problems:

1. You would not know the app was misconfigured until a request hit that code path.
2. You would have to search every file to find all the variables the app depends on.

With `Config::from_env()` called once in `main.rs`, the app fails immediately at startup if anything is missing — before it accepts a single request.

---

## Why is env var naming case-sensitive?

On Linux and macOS, environment variable names are case-sensitive at the OS level. `JWT_SECRET` and `Jwt_SECRET` are two completely different variables. Convention is ALL_CAPS_SNAKE_CASE for env vars. This is why the typo `"Jwt_SECRET"` would have caused a silent failure at runtime — the variable would never be found even if it was correctly set in `.env`.

---

## How this connects to the rest of Leewah

In `main.rs` (not built yet), `Config::from_env()` will be called once and the result will be stored in Axum's shared state. Every route handler that needs a database connection or the JWT secret will receive it from state — not by reading env vars directly.

```
main.rs
  └── Config::from_env()          ← reads all vars once
        └── passed into Axum state
              └── handlers extract what they need from state
```

---

## Key Rust concepts used here

| Concept | Where | What it does |
|---|---|---|
| `Result<T, E>` | return type of `from_env()` | represents success or failure without exceptions |
| `?` operator | after each `map_err(...)` | returns the error early if the result is `Err` |
| `.unwrap_or_else()` | on `port` | provides a fallback value instead of panicking |
| `.parse()` | on `port` | converts a `String` into another type (`u32`) |
| `.map_err()` | everywhere | replaces a generic error with a specific message |
| `pub` | on struct and fields | makes them accessible from other modules like `main.rs` |
