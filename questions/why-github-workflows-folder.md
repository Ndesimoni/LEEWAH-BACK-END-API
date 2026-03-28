## Question
Why must the CI file go in a folder called `.github/workflows/` specifically? Can it go anywhere else?

## Answer
(Answered through discussion — it must be that specific path)

## Full Explanation
No — it cannot go anywhere else. GitHub Actions is hardcoded to scan exactly `.github/workflows/` for `.yml` files. If you put the file in `ci/workflows/`, `config/`, or anywhere else, GitHub will never find it and nothing will run.

Each `.yml` file inside `.github/workflows/` is one workflow. You can have multiple:
```
.github/workflows/
├── ci.yml        # runs on every push — lint, test, build
├── deploy.yml    # runs when you merge to main
└── release.yml   # runs when you create a release tag
```

The workflow triggers are defined under `on:`:
```yaml
on:
  push:           # runs on every push to any branch
  pull_request:   # runs on every pull request
```

The Leewah CI workflow runs 4 checks in order:
1. `cargo fmt --all -- --check` — fails if code is not formatted
2. `cargo clippy --all-targets -- -D warnings` — fails if there are any Clippy warnings
3. `cargo test --all` — fails if any test fails

If any step fails, GitHub blocks the PR from merging and notifies you immediately.
