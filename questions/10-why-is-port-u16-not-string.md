## Question
Why is `port` a `u16` and not a `String` in the Config struct?

## Answer
User was working towards the answer — knew port numbers go from 0 to 65535 and that u16 holds exactly 0 to 65535.

## Full Explanation
It's not a coincidence. `u16` (unsigned 16-bit integer) holds values from 0 to 65535 — which is **exactly** the valid range for TCP/UDP port numbers. This is by design in the networking standard.

Using `u16` instead of `String` means:
- The type itself enforces the valid range — you can't accidentally set port to 99999 or "abc"
- You can pass it directly to Axum's `bind()` function which expects a number, not a string
- The `.parse()` call in config.rs converts the env var string "8080" into the number 8080

This is a core Rust philosophy — **make invalid states unrepresentable**. If the type is `u16`, an invalid port number simply cannot exist.
