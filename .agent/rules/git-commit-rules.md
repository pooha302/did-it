---
trigger: always_on
glob:
description: Git commit and push rules
---

# Git Commit Rules

## When to Commit
- **ONLY** perform `git commit` and `git push` when the user explicitly requests it
- Common user requests that indicate commit intent:
  - "commit"
  - "commit and push"
  - "push"
  - "save changes"
  - "commit these changes"

## When NOT to Commit
- Do NOT automatically commit after making code changes
- Do NOT commit as part of completing a task unless explicitly requested
- Do NOT commit when the user only asks to "fix" or "update" something

## Examples

### ✅ DO Commit
```
User: "commit and push"
User: "commit these changes"
User: "save to git"
```

### ❌ DON'T Commit
```
User: "fix the bug"
User: "update the version"
User: "add a new feature"
```

After completing the requested changes, wait for the user to explicitly request a commit.
