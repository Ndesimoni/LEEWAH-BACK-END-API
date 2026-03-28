---
name: Save questions and answers to questions/ folder
description: Every time Claude asks the user a question, save the question and the user's answer to the questions/ folder as a markdown file.
type: feedback
---

After every question asked to the user (the "think first" questions during learning), save both the question and the user's answer to a markdown file in the `questions/` folder at the project root.

**Why:** The user wants to review all questions and answers after sessions to reinforce their learning.

**How to apply:**
- File naming: use a short slug, e.g. `questions/what-is-a-connection-pool.md`
- Format:
  ```
  ## Question
  [the question asked]

  ## Answer
  [the user's answer]

  ## Full Explanation
  [the explanation given]
  ```
- Save after the user answers, not before.
- Do this for every learning question, no exceptions.
