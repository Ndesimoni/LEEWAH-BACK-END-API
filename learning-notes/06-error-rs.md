# Error Handling — `src/error.rs`

## The Problem Without a Unified Error Type

Imagine you have 50 route handlers in your API. Each one can fail in different ways:
- The database query fails (sqlx error)
- The user is not logged in
- The requested resource doesn't exist
- The user's input is invalid

Without a unified error type, every handler would need to decide:
- What HTTP status code to return?
- What JSON shape to return?
- How to handle a sqlx error vs a missing resource vs a bad input?

This leads to inconsistent responses, repeated code, and bugs.

---

## The Solution — One `AppError` Enum

In Leewah, **all errors flow through one type**: `AppError`. Every handler returns it. Every error maps to exactly one place.

```rust
pub enum AppError {
    Unauthorized,               // 401 — not logged in
    Forbidden,                  // 403 — logged in but no permission
    NotFound(String),           // 404 — resource doesn't exist
    ValidationError(String),    // 422 — bad user input
    InsufficientBalance,        // 422 — wallet too low
    RateLimitExceeded,          // 429 — too many requests
    Internal(anyhow::Error),    // 500 — something broke internally
}
```

Think of it like a menu of all the ways things can go wrong. Every error in the entire app is one of these.

---

## Why Some Variants Hold a String and Others Don't

- `Unauthorized` always means the same thing — "you are not logged in." No extra info needed.
- `Forbidden` always means "you don't have permission." Same every time.

But `NotFound` could refer to many things:
- A user not found
- A child not found
- A school not found

So it carries a `String` to be specific:

```rust
// In a handler
return Err(AppError::NotFound("child not found".to_string()));
return Err(AppError::NotFound("school not found".to_string()));
```

Same for `ValidationError` — the message tells the user exactly what was wrong with their input:

```rust
return Err(AppError::ValidationError("phone number is required".to_string()));
return Err(AppError::ValidationError("amount must be at least 1 FCFA".to_string()));
```

---

## `IntoResponse` — Turning Errors into HTTP Responses

Axum needs to know how to turn your `AppError` into an HTTP response. You teach it by implementing the `IntoResponse` trait:

```rust
impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            AppError::Unauthorized        => (StatusCode::UNAUTHORIZED, "Unauthorized".to_string()),
            AppError::Forbidden           => (StatusCode::FORBIDDEN, "Forbidden".to_string()),
            AppError::NotFound(msg)       => (StatusCode::NOT_FOUND, msg.to_string()),
            AppError::ValidationError(msg)=> (StatusCode::UNPROCESSABLE_ENTITY, msg.to_string()),
            AppError::InsufficientBalance => (StatusCode::UNPROCESSABLE_ENTITY, "Insufficient balance".to_string()),
            AppError::RateLimitExceeded   => (StatusCode::TOO_MANY_REQUESTS, "Rate limit exceeded".to_string()),
            AppError::Internal(_)         => (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error".to_string()),
        };

        (status, Json(json!({ "error": message }))).into_response()
    }
}
```

Every error variant maps to:
1. An HTTP status code
2. A JSON body: `{ "error": "message" }`

This is the **only place in the entire codebase** where HTTP status codes are assigned. No handler ever writes `StatusCode::NOT_FOUND` — they just return `AppError::NotFound(...)` and this function handles the rest.

---

## HTTP Status Codes Used

| Variant | Status Code | Meaning |
|---|---|---|
| `Unauthorized` | 401 | Not logged in |
| `Forbidden` | 403 | Logged in but no access |
| `NotFound` | 404 | Resource doesn't exist |
| `ValidationError` | 422 | Bad user input |
| `InsufficientBalance` | 422 | Wallet balance too low |
| `RateLimitExceeded` | 429 | Too many requests |
| `Internal` | 500 | Server broke internally |

---

## Why Internal Errors Are Hidden

When a database query fails, sqlx gives you an error like:

```
error: column "usr_id" of relation "users" does not exist
```

You must **never** send this to the client. It exposes:
- Your database table names
- Your column names
- Internal implementation details
- Potential attack surface

Instead, `Internal(_)` ignores the actual error (`_` means "I know it's there but I'm not using it here") and returns a safe generic message to the client:

```json
{ "error": "Internal server error" }
```

The real error is logged server-side (via tracing) so you can still debug it — but the client never sees it.

---

## The `internal()` Helper — Wrapping External Errors

External libraries (sqlx, redis) return their own error types. To convert them into `AppError::Internal`, you'd normally write:

```rust
AppError::Internal(anyhow::anyhow!(e.to_string()))
```

That's verbose. The helper wraps this:

```rust
impl AppError {
    pub fn internal(e: impl std::error::Error) -> Self {
        AppError::Internal(anyhow::anyhow!(e.to_string()))
    }
}
```

`impl std::error::Error` means "accept any type that is an error" — sqlx errors, redis errors, IO errors, anything.

Now in handlers you can write:

```rust
// Without helper — verbose
let user = get_user(id).await.map_err(|e| AppError::Internal(anyhow::anyhow!(e.to_string())))?;

// With helper — clean
let user = get_user(id).await.map_err(AppError::internal)?;
```

Both do the same thing. The helper just keeps your code clean.

---

## How a Handler Uses AppError

```rust
pub async fn get_child(
    Path(child_id): Path<Uuid>,
    Extension(user): Extension<AuthUser>,
    State(db): State<PgPool>,
) -> Result<Json<Child>, AppError> {

    let child = sqlx::query_as!(Child, "SELECT * FROM children WHERE id = $1", child_id)
        .fetch_optional(&db)
        .await
        .map_err(AppError::internal)?;   // sqlx error → AppError::Internal → 500

    let child = child.ok_or_else(|| AppError::NotFound("child not found".to_string()))?;  // → 404

    if child.parent_id != user.id {
        return Err(AppError::Forbidden);  // → 403
    }

    Ok(Json(child))
}
```

Notice:
- The handler never writes a status code directly
- Every failure path returns an `AppError` variant
- The `IntoResponse` impl handles everything else automatically

---

## Summary

| Concept | What it does |
|---|---|
| `AppError` enum | One type to represent all possible errors |
| `IntoResponse` impl | Converts each variant to the right HTTP status + JSON |
| `String` in variants | Lets handlers give specific error messages |
| `Internal(_)` | Hides raw external errors from clients |
| `.internal()` helper | Clean one-liner to wrap any external error |
| Single source of status codes | Status codes live in one place, not scattered across handlers |
