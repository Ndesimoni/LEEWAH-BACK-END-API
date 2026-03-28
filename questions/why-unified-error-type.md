## Question
Without a unified error type, what would happen if you had 50 route handlers all returning different kinds of errors in different formats? Why is that a problem?

## Answer
"we would need to do the import in every file and create the enum as well and the impl block"

## Full Explanation
That's part of it — but the bigger problem is what the mobile app receives.

If every handler returns errors in a different shape:
- One handler returns `{ "message": "not found" }`
- Another returns `{ "error": "unauthorized" }`
- Another returns a plain string `"something went wrong"`

The React Native app can't reliably handle errors. The mobile developer has to write different error handling code for every single endpoint — checking `response.message` here, `response.error` there.

The real problems are:
1. **Inconsistency** — the mobile app can't rely on a single error shape
2. **Duplicated logic** — every handler decides its own status code and JSON format
3. **Easy to get wrong** — one developer returns 404, another returns 200 with an error inside

The solution is one `AppError` enum:
- Every handler returns the same type
- Every error maps to exactly one HTTP status code
- Every error produces the same JSON: `{ "error": "message" }`
- The mobile app always knows what to expect

The `IntoResponse` impl is the key — it is the single place in the entire codebase where HTTP status codes are assigned. No handler ever writes `StatusCode::NOT_FOUND` directly — they just return `AppError::NotFound("child not found".to_string())` and the impl handles the rest.

The `Internal(_)` variant uses `_` to intentionally discard the real error — it gets logged server-side but never sent to the client, preventing leaking internal details like database table names or column names.
