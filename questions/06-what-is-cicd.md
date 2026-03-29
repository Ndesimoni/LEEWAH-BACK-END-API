## Question
What do you think CI/CD stands for and what does it do?

## Answer
"continuous integration and continuous deployment, this means that you can add and reduce and deploy code without having to write tests over and over"

## Full Explanation
You got the words right but the tests part needs clarifying.

**CI — Continuous Integration**
Every time you push code to GitHub, an automated system runs a set of checks:
- Does it compile?
- Do the tests pass?
- Does Clippy find any warnings?
- Is the code formatted correctly?

If any check fails you get notified immediately and the code is blocked from merging. The key point: CI does NOT remove the need to write tests. It is the opposite — CI runs your tests automatically on every push so you never forget to run them. You still write the tests. CI just makes sure they always execute.

**CD — Continuous Deployment**
After CI passes, the code is automatically deployed to production. No manual steps. Push code → tests pass → live on the server.

Without CI/CD:
- You write tests, sometimes forget to run them, merge broken code

With CI/CD:
- Every push triggers checks automatically, broken code gets caught before it merges, passing code deploys automatically

For Leewah, the CI pipeline is in `.github/workflows/ci.yml` and runs on every push and pull request:
1. Check formatting (`cargo fmt --check`)
2. Check lints (`cargo clippy`)
3. Run tests (`cargo test`)
