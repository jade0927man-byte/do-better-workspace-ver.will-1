---
description: 전체 할 일 모아보기 (읽기 전용)
allowed-tools: Read, Glob, Bash
---

# /todos - 할 일 모아보기

todos.md에 모인 전체 할 일을 보여줍니다.
할 일 추가는 `/daily-note`에서, 여기는 보기 전용입니다.

## 사용법

```
/todos              # 전체 할 일 보기
/todos today        # 오늘 할 일만
/todos overdue      # 3일 이상 밀린 것들
/todos project      # 프로젝트별 그룹화
```

## 작동 방식

1. `./40-personal/46-todos/todos.md` 읽기
2. 인자에 따라 필터링/그룹화
3. 보기 좋게 출력

**참고:**
- todos.md는 `/daily-review`가 Daily Note들에서 미완료 항목을 자동 수집하여 동기화합니다
- 할 일을 추가하려면 `/daily-note`를 사용하세요
- 할 일을 완료하면 Daily Note에서 `- [x]`로 체크하세요
