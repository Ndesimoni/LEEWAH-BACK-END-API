## Question
The current `main.rs` has `fn main()`. But our API needs to handle thousands of requests at the same time. What do you think `async` means and why do we need it for a web server?

## Answer
"with async we can write non-blocking code. that is if a task is not yet done we can move on and start doing something else, while that task will continue running in the background, then when that task is done it gives us the result"

## Full Explanation
Exactly right. Without async, a server handles one request at a time — each request blocks the thread while waiting for the database, making all other requests queue up.

With async, while one request is waiting for a database query (5ms), the server moves on to start handling the next request. All queries run concurrently and respond nearly together.

In Rust, async is powered by a runtime called **Tokio**. Tokio manages all the "do this while waiting for that" operations. Axum is built on top of Tokio.

That's why `main.rs` uses:
```rust
#[tokio::main]
async fn main() {
    // server starts here
}
```

`#[tokio::main]` is a macro that starts the Tokio runtime and makes `main` async. Without it, you cannot use `async/await` in your program.

Key terms:
- `async fn` — declares a function as asynchronous
- `await` — pauses the current task and lets others run while waiting for a result
- `Tokio` — the async runtime that powers everything
- Non-blocking — the thread does useful work instead of sitting idle waiting
