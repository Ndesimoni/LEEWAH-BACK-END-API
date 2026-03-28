# 07 — config.rs: Loading Environment Variables in Rust

## What we built

`src/config.rs` is a single struct called `Config` that reads every environment variable the app needs when it first starts up. It is the only file in the entire codebase that calls `std::env::var()`.

---

## The Final Struct

```rust
use std::env::var;

pub struct Config {
    pub port: u16,
    pub database_url: String,
    pub jwt_secret: String,
    pub redis_url: String,
    pub jwt_access_expiry_minutes: u64,
    pub jwt_refresh_expiry_days: u64,
}
```

Each field maps directly to one environment variable. The types matter:

- `port` is `u16` — port numbers only go up to 65535, which fits in a 16-bit unsigned integer
- `jwt_access_expiry_minutes` and `jwt_refresh_expiry_days` are `u64` — time values, always positive
- The rest are `String` because connection strings and secrets are just text

---

## The `from_env()` method

This is the only way to build a `Config`. It returns `Result<Self, String>` — either a fully built `Config` or a clear error message explaining what went wrong.

### Optional field with a default (port)

```rust
port: var("PORT")
    .unwrap_or_else(|_| "8080".to_string())
    .parse()
    .map_err(|_| "PORT must be a number".to_string())?
```

- `var("PORT")` — reads the PORT env var, returns `Result<String, VarError>`
- `.unwrap_or_else(|_| "8080".to_string())` — if PORT is missing, use "8080" as default
- `.parse()` — converts the string "8080" into the number `8080` (type `u16`)
- `.map_err(...)` — if parse fails, replace the generic error with a readable message
- `?` — if anything failed, return the error immediately from `from_env()`

### Required string fields (database_url, jwt_secret, redis_url)

```rust
database_url: var("DATABASE_URL")
    .map_err(|_| "DATABASE_URL is required".to_string())?
```

No default — if the variable is missing, fail immediately. The app should never start without a database URL.

### Required numeric fields (jwt_access_expiry_minutes, jwt_refresh_expiry_days)

```rust
jwt_access_expiry_minutes: var("JWT_ACCESS_EXPIRY_MINUTES")
    .map_err(|_| "JWT_ACCESS_EXPIRY_MINUTES is required".to_string())?
    .parse()
    .map_err(|_| "JWT_ACCESS_EXPIRY_MINUTES must be a number".to_string())?
```

Two `?` operators — one for the missing variable, one for a bad value (e.g. someone sets it to "abc").

---

## How it connects to main.rs

In `main.rs`, config is loaded as the very first thing:

```rust
mod config;  // tells Rust this module exists

dotenvy::dotenv().ok();  // loads .env file (ok() = don't crash if no .env)

let config = config::Config::from_env().expect("Failed to load config");
```

The port is then used when binding the server:

```rust
let listener = TcpListener::bind(format!("0.0.0.0:{}", config.port)).await.unwrap();
```

No more hardcoded `8080`. The port now comes from the environment.

---

## Why `mod config;` in main.rs?

Rust does not automatically scan your `src/` folder for files. You have to explicitly declare every module with `mod`. Without `mod config;` in `main.rs`, the compiler does not know `config.rs` exists and will not compile it.

---

## Why one struct instead of calling `var()` everywhere?

Two reasons:

1. **Fail fast** — if a required variable is missing, the app crashes at startup with a clear message, before it accepts a single request. Without this, you'd only discover a missing variable when a specific request triggered that code path.

2. **Single source of truth** — all variables are declared in one file. Any developer can open `config.rs` and immediately see every env var the app depends on.

---

## Key Rust Concepts

| Concept | What it does |
|---|---|
| `Result<T, E>` | Represents success (`Ok`) or failure (`Err`) — no exceptions in Rust |
| `?` operator | If the result is `Err`, return it immediately from the current function |
| `.unwrap_or_else()` | Provides a fallback value instead of panicking when `Err` |
| `.parse()` | Converts a `String` into another type — fails if the string is not valid |
| `.map_err()` | Replaces a generic error with a human-readable message |
| `pub` | Makes the struct and its fields accessible from other modules |
| `mod config;` | Declares a module — Rust won't compile a file unless it's declared |
| `u16` | 16-bit unsigned integer — correct type for port numbers (max 65535) |
| `u64` | 64-bit unsigned integer — used for time values like expiry minutes |
