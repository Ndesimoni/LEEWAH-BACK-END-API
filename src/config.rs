use std::env::var;

pub struct Config {
    pub port: u32,
    pub database_url: String,
    pub jwt_secret: String,
    pub redis_url: String,
}

impl Config {
    pub fn from_env() -> Result<Self, String> {
        Ok(Self {
            //port set up */
            port: var("PORT")
                .unwrap_or_else(|_| "8080".to_string())
                .parse()
                .map_err(|_| "PORT must be a number".to_string())?,

            //data base url */
            database_url: var("DATABASE_URL")
                .map_err(|_| "DATABASE_URL is required".to_string())?,

            //jwt secret */
            jwt_secret: var("JWT_SECRET").map_err(|_| "JWT_SECRET is required".to_string())?,

            //redis url
            redis_url: var("REDIS_URL").map_err(|_| "REDIS_URL is required".to_string())?,
        })
    }
}

// ─── HOW THIS FILE WORKS ─────────────────────────────────────────────────────
//
// `Config` is a plain struct that holds every value the app needs from the
// environment. The only way to build one is `Config::from_env()`, which reads
// all variables at startup and fails fast if any required one is missing.
//
// WHY one struct instead of calling `std::env::var` everywhere?
//   Calling `var()` scattered across the codebase makes it impossible to know
//   which env vars the app needs without reading every file. A single struct
//   gives us one place to audit and one place to update when a new variable
//   is added.
//
// WHY call it only once (in main.rs)?
//   Environment variables are process-global state. Reading them once and
//   passing the struct around via Axum state means every handler gets a
//   typed, validated value — not a raw string that might be missing.
//
// FIELDS
//   port         – TCP port Axum binds to. Optional; defaults to 8080.
//   database_url – Full Postgres connection string used by sqlx to create
//                  the shared PgPool. Required — app won't start without it.
//   jwt_secret   – Signing key for JWT access tokens. Must be kept secret.
//                  Rotating this key invalidates all active sessions.
//   redis_url    – Connection string for Redis. Used by OTP storage,
//                  rate limiting, idempotency keys, and response caching.
//
