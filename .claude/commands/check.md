Run a full quality check on the Leewah API codebase and report all issues.

Execute the following steps in order:

1. **Format check**
   Run: `cargo fmt --check`
   Report any files that are not correctly formatted.

2. **Lint check**
   Run: `cargo clippy -- -D warnings`
   Report every warning and error with the file path and line number.

3. **Compile check**
   Run: `cargo check`
   Report any compilation errors.

4. **Test suite**
   Run: `cargo test`
   Report which tests passed and which failed. Show the output of any failed tests.

5. **Unused dependencies**
   Run: `cargo +nightly udeps` if available, otherwise skip and note it.

After all steps, produce a summary report in this format:

---
## Check Report

### Format
- [ ] Passed / [x] Failed — list affected files

### Clippy
- [ ] Passed / [x] Failed — list each warning/error with location

### Compile
- [ ] Passed / [x] Failed — list errors

### Tests
- [ ] Passed / [x] Failed — N passed, N failed
  - Failed: list test names and failure reason

### Overall
PASS or FAIL
---

If everything passes, confirm the codebase is clean. If anything fails, fix each issue immediately and re-run the affected check to confirm the fix before moving on. Do not leave failures unresolved.
