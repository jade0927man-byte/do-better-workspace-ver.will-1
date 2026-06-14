# Claude Code Hooks - Source of Truth

> **Source**: [code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks)
> **Updated**: 2026-05-25 (guide-sync 2026-05-25 반영: 아래 🆕 블록)
> **Purpose**: Hook 설계 시 유일한 참조 문서. 사용자의 `daily-backup.sh` 크론, 자동 린팅, 권한 자동 승인 같은 자동화 설계 시 먼저 읽을 것.

---

## 🆕 2026-05-25 sync 반영

**훅 이벤트 대폭 추가** (기존 PreToolUse·PostToolUse·SessionStart·UserPromptSubmit·Stop 외):
- `InstructionsLoaded`(CLAUDE.md/rules 로드 시 — 어떤 룰이 로드됐나 디버깅), `SessionEnd`, `PreCompact`/`PostCompact`, `ConfigChange`, `CwdChanged`, `FileChanged`(watch한 파일 변경), `PermissionRequest`/`PermissionDenied`, `PostToolUseFailure`, `PostToolBatch`, `SubagentStart`/`SubagentStop`, `TaskCreated`/`TaskCompleted`, `UserPromptExpansion`, `Setup`, `Notification` 등.

**훅 타입 4종** (기존 command 외):
- `http`(URL 호출), `mcp_tool`(MCP 도구 실행), `prompt`(모델에 질의), `agent`(에이전트 검증).

**구성**:
- `if` 필드로 조건부 실행: `"if": "Bash(git *)"` (permission 룰 문법).
- matcher: `"*"`/`"Edit|Write"`/regex/`"mcp__server__.*"`. SessionStart는 `startup`/`resume`/`clear`/`compact`.
- **스킬·서브에이전트 frontmatter에 `hooks:`** 넣어 그 컴포넌트 활성 중에만 작동하는 훅 가능.
- exit 0=성공(stdout JSON), exit 2=블로킹(stderr). `${CLAUDE_PROJECT_DIR}` 등 치환.
- 타임아웃 기본 600s(UserPromptSubmit 30s), prompt 30s, agent 60s.

> 사용자 SessionStart 훅(L1~L5 주입)·PromptSubmit 훅(vague 감지)은 이 체계 위에 있음. `InstructionsLoaded`는 "어떤 룰 파일이 실제 로드됐나" 추적에 유용.

---

## 1. Hooks 개요

**Hook**은 Claude Code의 라이프사이클 특정 시점에 자동 실행되는 **셸 명령 / HTTP 엔드포인트 / LLM 프롬프트**. 사용자가 `settings.json`에 정의.

### 언제 쓰나

- **정책 강제**: `rm -rf`, 민감 파일 접근 차단
- **자동화**: 안전한 명령 자동 승인, 파일 저장 시 린터 실행
- **감사/로깅**: 도구 사용 내역 기록
- **외부 연동**: Slack 알림, CI 트리거, 대시보드 업데이트
- **환경 관리**: 세션 시작 시 env 변수 세팅, 디렉토리 변경 감지

---

## 2. 모든 Hook 이벤트 (26종)

| 이벤트 | 언제 발생 | 차단 가능? |
|-------|---------|----------|
| **SessionStart** | 세션 시작/재개 | X |
| **UserPromptSubmit** | 사용자 프롬프트 제출 시 | O |
| **UserPromptExpansion** | 슬래시 커맨드 확장 시 | O |
| **PreToolUse** | 도구 실행 직전 | O |
| **PermissionRequest** | 권한 다이얼로그 표시 시 | O |
| **PermissionDenied** | Auto 모드 분류기가 거부 시 | X |
| **PostToolUse** | 도구 성공 시 | X (재실행 불가) |
| **PostToolUseFailure** | 도구 실패 시 | X |
| **Stop** | Claude 응답 종료 시 | O |
| **StopFailure** | API 오류로 종료 시 | X |
| **SubagentStart** / **SubagentStop** | 서브에이전트 생성/종료 | 종료만 O |
| **TaskCreated** / **TaskCompleted** | 태스크 생성/완료 | O |
| **Notification** | 알림 발송 | X |
| **TeammateIdle** | 에이전트팀 멤버 유휴 | O |
| **ConfigChange** | 설정 파일 변경 | O |
| **CwdChanged** | 작업 디렉토리 변경 | X |
| **FileChanged** | 감시 파일 디스크 변경 | X |
| **WorktreeCreate** / **WorktreeRemove** | Worktree 생성/삭제 | 생성만 O |
| **InstructionsLoaded** | CLAUDE.md·rules 로드 | X |
| **PreCompact** / **PostCompact** | 컨텍스트 압축 전/후 | 전만 O |
| **Elicitation** / **ElicitationResult** | MCP 서버가 사용자 입력 요청 | O |
| **SessionEnd** | 세션 종료 | X |

**사용자에게 가장 자주 쓰일 3종**:
- `PreToolUse` — 도구 실행 직전 검증/차단/수정
- `PostToolUse` — 파일 저장 후 린터·포맷터 실행
- `SessionStart` — 세션 시작 시 환경 변수·초기 컨텍스트 주입

---

## 3. 설정 구조 (settings.json)

3단 중첩: **이벤트 → 매처 그룹 → 핸들러 배열**.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(rm *)",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-rm.sh"
          }
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-style.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [{ "type": "command", "command": "/path/to/setup.sh" }]
      }
    ]
  }
}
```

### Hook 위치와 범위

| 위치 | 범위 | 공유? |
|-----|-----|-----|
| `~/.claude/settings.json` | 모든 프로젝트 | X |
| `.claude/settings.json` | 단일 프로젝트 | O (git 커밋) |
| `.claude/settings.local.json` | 단일 프로젝트, 로컬 | X (gitignore) |
| 관리형 정책 (Managed) | 조직 전체 | O (IT 관리) |
| Plugin `hooks/hooks.json` | 플러그인 활성 시 | O |
| Skill/Agent frontmatter `hooks:` | 해당 컴포넌트 생명주기만 | O |

---

## 4. Matcher 패턴

`matcher` 필드는 hook이 언제 발화하는지 필터링. 평가 규칙이 값에 따라 달라짐.

| 매처 값 | 평가 방식 | 예시 |
|--------|---------|-----|
| `"*"`, `""`, 생략 | 전체 매치 | 모든 발생 시 |
| 영문자·숫자·`_`·`\|`만 | 정확 일치 또는 `\|` 구분 리스트 | `Bash`, `Edit\|Write` |
| 그 외 문자 포함 | JavaScript 정규식 | `^Notebook`, `mcp__memory__.*` |

### MCP 도구 매칭

MCP 도구는 `mcp__<server>__<tool>` 형식:
- `mcp__memory__create_entities` — 특정 도구
- `mcp__memory__.*` — 메모리 서버의 모든 도구
- `mcp__.*__write.*` — 모든 서버의 write 계열 도구

### `if` 필드 (더 좁히기)

`PreToolUse`, `PostToolUse`, `PermissionRequest` 등 도구 이벤트에서 권한 규칙 문법으로 추가 필터링:

```json
{
  "matcher": "Bash",
  "hooks": [{
    "type": "command",
    "if": "Bash(git push *)",
    "command": "/path/to/validate.sh"
  }]
}
```

---

## 5. Hook 핸들러 4종 타입

### a. `type: "command"` — 셸 명령 (가장 흔함)

```json
{
  "type": "command",
  "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/my-hook.sh",
  "if": "Bash(rm *)",
  "timeout": 600,
  "statusMessage": "Running security check...",
  "async": false,
  "shell": "bash",
  "once": false
}
```

**환경 변수**:
- `$CLAUDE_PROJECT_DIR` — 프로젝트 루트
- `${CLAUDE_PLUGIN_ROOT}` — 플러그인 설치 디렉토리
- `${CLAUDE_PLUGIN_DATA}` — 플러그인 영속 데이터 디렉토리

### b. `type: "http"` — HTTP POST

```json
{
  "type": "http",
  "url": "http://localhost:8080/hooks/pre-tool-use",
  "headers": { "Authorization": "Bearer $MY_TOKEN" },
  "allowedEnvVars": ["MY_TOKEN"],
  "timeout": 30
}
```

비-2xx 응답·타임아웃·연결 실패는 **비차단** 에러 (실행 계속). 차단하려면 2xx + 결정 JSON 반환.

### c. `type: "prompt"` — Claude 모델에 질의

```json
{
  "type": "prompt",
  "prompt": "Is this command safe? $ARGUMENTS",
  "model": "claude-opus",
  "timeout": 30
}
```

### d. `type: "agent"` — 서브에이전트 검증 (실험적)

---

## 6. Input / Output

### 모든 이벤트 공통 Input (stdin JSON)

```json
{
  "session_id": "abc123",
  "transcript_path": "/home/user/.claude/projects/.../transcript.jsonl",
  "cwd": "/current/working/directory",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse"
}
```

### Exit Code 의미 (Command Hooks)

| Exit Code | 의미 | 효과 |
|----------|-----|-----|
| **0** | 성공 | stdout을 JSON으로 파싱, 지정된 액션 수행 |
| **2** | 차단 에러 | stdout 무시, stderr 에러 메시지로, 액션 차단 (가능 이벤트만) |
| **그 외** | 비차단 에러 | stderr 표시, 실행 계속 |

**중요**: 대부분 이벤트에서 exit 1은 **비차단**. 차단하려면 반드시 **exit 2**.

### PreToolUse 출력 예시

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask|defer",
    "permissionDecisionReason": "Explanation",
    "updatedInput": { "command": "safe version" },
    "additionalContext": "Context for Claude"
  }
}
```

### 전역 출력 필드

```json
{
  "continue": true,
  "stopReason": "continue=false일 때 사용자에게 보이는 메시지",
  "suppressOutput": false,
  "systemMessage": "사용자에게 표시할 경고"
}
```

---

## 7. 실전 예시 (사용자 유스케이스 중심)

### 예시 1: `rm -rf` 차단

`.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "if": "Bash(rm *)",
        "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-rm.sh"
      }]
    }]
  }
}
```

`.claude/hooks/block-rm.sh`:
```bash
#!/bin/bash
COMMAND=$(jq -r '.tool_input.command')
if echo "$COMMAND" | grep -q 'rm -rf'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Destructive rm -rf blocked by policy"
    }
  }'
fi
exit 0
```

### 예시 2: 파일 저장 후 린터 자동 실행

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/run-linter.sh"
      }]
    }]
  }
}
```

### 예시 3: 세션 시작 시 환경 세팅

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "startup",
      "hooks": [{
        "type": "command",
        "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/init-env.sh"
      }]
    }]
  }
}
```

`init-env.sh`:
```bash
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"
fi
jq -n '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: "Dev env loaded"
  }
}'
exit 0
```

---

## 8. Skill/Agent 내부 Hook

스킬·에이전트 frontmatter에 hook 정의 가능. 해당 컴포넌트 활성 기간에만 작동.

```yaml
---
name: secure-ops
description: ...
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh"
---
```

서브에이전트에서 `Stop` 훅은 자동으로 `SubagentStop`으로 변환됨.

---

## 9. 보안·베스트 프랙티스

1. `if` 필드로 불필요한 서브프로세스 생성 방지
2. `$CLAUDE_PROJECT_DIR` 사용해 경로 휴대성 확보
3. JSON 입력 파싱 시 injection 주의 (jq 쓰면 안전)
4. 차단은 일관되게 **exit 2** 사용
5. hook 실패하면 실제 액션도 차단되므로 충분한 테스트 필요
6. 민감 정보 hook은 `.claude/settings.local.json` (gitignore)에 둘 것
7. HTTP hook은 `allowedEnvVars` 명시해 환경변수 누출 방지

---

## 10. 관리 명령

- `/hooks` — 현재 설정된 모든 hook 읽기 전용 브라우저
- `disableAllHooks: true` — 설정 유지하고 일시 비활성화

---

## 사용자 사업 맥락

- **현재 사용 중**: `daily-backup.sh` 는 **crontab**(시스템 cron)으로 돌아가는 일반 스크립트 — Claude Code의 hook이 **아님**. Claude Code hooks는 Claude 세션 내부 이벤트에만 반응.
- **도입 권장 시나리오**:
  - 특정 도메인 파일(예: 결산·정산 스킬) Edit/Write 후 자동 검증 스킬 호출
  - `.env`·금융 스크린샷 등 민감 파일 Read 차단 (이미 `.gitignore`는 있지만 `deny` permission + hook으로 이중화)
  - SessionStart hook으로 오늘 Daily Note 자동 로드
