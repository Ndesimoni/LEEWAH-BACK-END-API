## Question
What do you think `Result::unwrap()` means based on the panic error? It says "called `Result::unwrap()` on an `Err` value" — what do you think `Result` and `unwrap()` are doing?

## Answer
"Result is an enum that can either return Ok or Err. Since there was already something running on port 8080, the error was returned and unwrap() is used to get the value out of it."

## Full Explanation
Exactly right. `Result<T, E>` is an enum with two variants:
- `Ok(T)` — success, contains the value
- `Err(E)` — failure, contains the error

`.unwrap()` says "give me the value inside `Ok`, but if it's `Err` — panic and crash immediately."

That's exactly what happened:
```
TcpListener::bind("0.0.0.0:8080") → Err(AddrInUse)
.unwrap() → panicked because it got Err instead of Ok
```

In production code you never use `.unwrap()` on fallible operations — you handle the error properly using `?` or `match`. But during early development it's useful because it tells you exactly what went wrong instead of silently failing.

The proper way in production would be:
```rust
let listener = TcpListener::bind("0.0.0.0:8080")
    .await
    .expect("Failed to bind to port 8080");
```

`.expect("message")` is like `.unwrap()` but lets you provide a custom panic message — making it easier to debug.
