---
trigger: always_on
glob:
description: Git commit 및 push 규칙
---

# Git Commit Rules

## When to Commit
- 사용자가 명시적으로 요청할 때**만** `git commit` 및 `git push`를 수행합니다.
- commit 의도를 나타내는 일반적인 사용자 요청:
  - "commit"
  - "commit and push"
  - "push"
  - "save changes"
  - "commit these changes"

## When NOT to Commit
- 코드 변경 후 자동으로 commit하지 마십시오.
- 명시적으로 요청하지 않는 한 작업을 완료하는 과정의 일부로 commit하지 마십시오.
- 사용자가 단순히 무언가를 "수정(fix)"하거나 "업데이트(update)"하라고 했을 때 commit하지 마십시오.

## Examples

### ✅ commit 수행
```
사용자: "commit and push"
사용자: "commit these changes"
사용자: "save to git"
```

### ❌ commit하지 않음
```
사용자: "버그 수정해줘"
사용자: "버전 업데이트해줘"
사용자: "새 기능 추가해줘"
```

요청된 변경 사항을 완료한 후, 사용자가 명시적으로 commit을 요청할 때까지 기다리십시오.
