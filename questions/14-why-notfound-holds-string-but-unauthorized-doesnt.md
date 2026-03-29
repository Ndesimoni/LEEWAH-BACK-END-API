## Question
Why do `NotFound` and `ValidationError` hold a `String`, but `Unauthorized` and `Forbidden` don't?

## Answer
Because they will return a custom string error for the various handlers, where the others just straight return the enum.

## Full Explanation
Exactly right.

- `Unauthorized` always means the same thing — "you are not logged in." No extra context needed.
- `Forbidden` always means "you don't have permission." Same every time.

But `NotFound` could refer to many different things depending on which handler returns it:
- "user not found"
- "child not found"
- "school not found"

So it carries a `String` so each handler can give a specific message. Same idea for `ValidationError` — the message tells the user exactly what was wrong with their input:

```rust
return Err(AppError::NotFound("child not found".to_string()));
return Err(AppError::ValidationError("phone number is required".to_string()));
```

The rule: if the error message is **always the same**, no String needed. If it varies **per handler**, carry a String.
