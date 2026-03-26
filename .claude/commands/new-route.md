Scaffold a new Axum route handler for the Leewah API.

The user will provide a domain name and a list of endpoints. For example: "wallet" with GET /wallet, POST /wallet/topup.

Follow these steps:

1. Read `src/routes/` to understand the existing handler structure before writing anything.
2. Create `src/routes/<domain>.rs` with the following structure:
   - Import: `axum`, `serde`, `validator`, `AppError`, `AppState`, `AuthUser` extractor
   - One request DTO struct per endpoint that has a body (derive `Deserialize`, `Validate`)
   - One response DTO struct per endpoint (derive `Serialize`)
   - One async handler function per endpoint returning `Result<Json<ResponseDto>, AppError>`
   - A `router()` function at the bottom that returns `Router<AppState>` with all routes wired up
3. Register the router in `src/main.rs` under `/api/v1/<domain>`.
4. Create a stub `src/services/<domain>.rs` with empty function signatures matching what the handlers call.
5. Add the new modules to `src/routes/mod.rs` and `src/services/mod.rs`.

Rules to follow:
- Handlers must be thin: validate input, call one service function, return result.
- Never put business logic inside a handler.
- Every handler that requires auth must accept `AuthUser` as a parameter.
- Parent-only routes must check `auth_user.account_type == "parent"` and return `AppError::Forbidden` if not.
- Use `#[serde(rename_all = "camelCase")]` on all request/response DTOs.
- All amounts are `i64` (FCFA integers), never `f64`.

Show the complete file contents for each file created or modified.
