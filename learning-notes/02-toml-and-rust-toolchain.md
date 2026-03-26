# TOML & rust-toolchain.toml

## What is TOML?

TOML stands for **Tom's Obvious, Minimal Language**.

It is a configuration file format — a way to write structured data in a file that is easy for humans to read and write. Think of it as an alternative to JSON or YAML, but designed to be simpler and more readable.

---

## Why Not Just Use JSON for Config Files?

Let's compare the same data in three formats:

**JSON:**
```json
{
  "toolchain": {
    "channel": "stable"
  },
  "server": {
    "port": 8080,
    "host": "localhost"
  }
}
```

**YAML:**
```yaml
toolchain:
  channel: stable
server:
  port: 8080
  host: localhost
```

**TOML:**
```toml
[toolchain]
channel = "stable"

[server]
port = 8080
host = "localhost"
```

TOML wins for config files because:
- `[section]` headers are clear and obvious
- Key = value is natural to read
- No brackets to forget to close like JSON
- No indentation sensitivity like YAML (YAML breaks if you get spaces wrong)

---

## Where You'll See TOML in This Project

| File | What it configures |
|---|---|
| `Cargo.toml` | Project name, version, dependencies |
| `rust-toolchain.toml` | Which Rust version to use |
| `sqlx.toml` (later) | sqlx CLI configuration |

TOML is the **standard config format across the entire Rust ecosystem**. You will see it constantly.

---

## How TOML Syntax Works

### Sections (Tables)
Square brackets define a section. Everything below belongs to that section until the next section starts.
```toml
[toolchain]
channel = "stable"

[database]
url = "postgres://localhost/leewah"
port = 5432
```

### Data types
```toml
name = "leewah"        # String (in quotes)
port = 8080            # Integer (no quotes)
debug = true           # Boolean
timeout = 30.5         # Float
```

### Arrays
```toml
features = ["ws", "multipart"]
```

### Nested (inline)
```toml
[dependencies]
axum = { version = "0.8", features = ["ws"] }
```

---

## What is rust-toolchain.toml?

`rust-toolchain.toml` is a file that tells `rustup` (the Rust version manager) which version of Rust to use for this specific project.

---

## How Rust Versioning Works

Rust has three release **channels**:

### stable
- Released every **6 weeks**
- Fully tested, production-ready
- What you use for all real projects
- Example: `1.87.0`

### beta
- The next stable release being tested
- Not ready for production
- Used by library authors to test compatibility ahead of time

### nightly
- Built every night from the latest code
- Has experimental features not yet in stable
- Can break at any time
- Used for research, tooling, and bleeding-edge features

**For the Leewah API: always stable.**

---

## Why Pin the Rust Version?

Imagine this scenario:
- You have Rust 1.85 installed
- Your colleague has Rust 1.87 installed
- A new language feature in 1.87 changes how some code compiles
- Your colleague's code works, yours doesn't
- You spend hours debugging something that isn't a code bug at all

`rust-toolchain.toml` solves this. When anyone runs any `cargo` command in the project folder, `rustup` reads this file first and says:

> "This project wants stable Rust. Let me make sure I'm using that."

If they don't have that version, `rustup` downloads it automatically.

---

## The Leewah rust-toolchain.toml

```toml
[toolchain]
channel = "stable"
```

That's the whole file. Simple but important.

You could also pin to a specific version number:
```toml
[toolchain]
channel = "1.87.0"
```

This is even stricter — nobody can use a different patch version. Useful for teams that want zero variation. For now `"stable"` is fine.

---

## Key Things to Remember

1. **TOML is the config language of Rust** — learn to read it, you'll see it everywhere
2. **`[section]`** defines a group of related settings
3. **Rust has three channels**: stable (production), beta (testing), nightly (experimental)
4. **Always use stable for production APIs**
5. **`rust-toolchain.toml` ensures everyone on the team uses the same compiler** — prevents "works on my machine" bugs
6. **`rustup` reads this file automatically** — you never have to think about it after creating it
