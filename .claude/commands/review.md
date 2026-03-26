Review the current file or a file specified by the user against the Leewah API rules in CLAUDE.md.

If no file is specified, review the file currently open or most recently edited.

Steps:

1. Read `CLAUDE.md` to load the full rules.
2. Read the target file completely.
3. Identify which layer the file belongs to (route/handler, service, model, middleware, migration) and apply the rules relevant to that layer.

Check for the following in every file:

**Safety**
- Any `unwrap()` or `expect()` not inside a `#[cfg(test)]` block
- Any `panic!` in non-test code
- Any hardcoded secrets, tokens, or credentials
- Any raw SQL string formatting (injection risk)

**Architecture**
- HTTP types (`Request`, `Response`, `StatusCode`, `Json`) imported in a service file
- Business logic (DB queries, calculations, rule enforcement) inside a route handler
- DB model structs used directly as request/response bodies

**Auth & Security**
- Protected handlers missing the `AuthUser` extractor
- Admin handlers missing the `AdminUser` extractor
- File upload handlers missing MIME type validation
- Payment handlers missing idempotency key check
- Webhook handlers missing HMAC signature verification

**Code Quality**
- Missing `#[validate]` attributes on request DTO fields
- `Option<T>` used on fields that should always be present
- `f64` or `f32` used for monetary amounts (must be `i64`)
- `println!` or `eprintln!` instead of `tracing::info!` / `tracing::error!`
- Missing error mapping (raw sqlx/redis errors leaking to return type)

**Consistency**
- Response structs missing `#[serde(rename_all = "camelCase")]`
- Timestamps not using `time::OffsetDateTime`
- Missing `deleted_at IS NULL` filter on soft-deletable table queries

Produce a review report in this format:

---
## Review: `<filename>`

### Critical (must fix before merging)
- Line N: description of issue

### Warnings (should fix)
- Line N: description of issue

### Suggestions (optional improvements)
- Line N: description of suggestion

### Verdict
APPROVED / NEEDS CHANGES
---

If there are critical issues, fix them immediately after the report. If there are only warnings or suggestions, list them and ask the user if they want them fixed.
