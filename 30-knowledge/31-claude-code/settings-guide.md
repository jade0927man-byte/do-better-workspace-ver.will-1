# Claude Code settings.json - Source of Truth

> **Source**: [code.claude.com/docs/en/settings](https://code.claude.com/docs/en/settings)
> **Updated**: 2026-05-25 (guide-sync 2026-05-25 반영: 아래 🆕 블록)
> **Purpose**: `settings.json`·`settings.local.json` 수정 시 유일한 참조 문서.

---

## 🆕 2026-05-25 sync 반영

**Auto Mode** (권한 프롬프트 자동 판정):
```json
{ "autoMode": { "allow": ["$defaults", "내 룰"], "soft_deny": ["..."], "hard_deny": ["$defaults"] },
  "useAutoModeDuringPlan": true }
```
- `permissions.defaultMode`에 `"auto"`·`"dontAsk"` 추가됨(기존 default/acceptEdits/plan/bypassPermissions). ⚠️ 중요 파일 혼재 워크스페이스는 적용 범위 신중히.

**스킬 제어**:
- `skillOverrides`: `{ "skill명": "on"|"name-only"|"user-invocable-only"|"off" }` — 스킬 가시성 제어.
- `skillListingBudgetFraction`(기본 0.01), `maxSkillDescriptionChars`(기본 1536).

**메모리**:
- `autoMemoryEnabled`(기본 true), `autoMemoryDirectory`(절대경로/`~`, user·policy settings에서만).

**기타 신규 키**: `effortLevel`, `alwaysThinkingEnabled`, `outputStyle`, `tui`("fullscreen"), `language`, `disableRemoteControl`(managed), `cleanupPeriodDays`, `plansDirectory`, `attribution`(commit/pr 문구). sandbox 블록 대폭 확장(filesystem allow/denyWrite·network allowedDomains 등).
- hot reload: permissions·hooks는 즉시, model·outputStyle은 재시작 필요.

> ⚠️ `~/.claude/settings.json`(전역)은 다온 직접 편집 불가(self-modification). `/tmp` 스크립트 우회. 프로젝트 `.claude/settings.local.json`은 편집 가능.

---

## 1. 설정 파일 위치와 우선순위

| 범위 | 경로 | 적용 | 공유? |
|-----|-----|-----|-----|
| **Managed** (조직) | macOS: `/Library/Application Support/ClaudeCode/` | 기기의 모든 사용자 | IT 배포 |
| **User** | `~/.claude/settings.json` | 사용자 모든 프로젝트 | X |
| **Project** | `.claude/settings.json` | 해당 프로젝트 | O (git 커밋) |
| **Local** | `.claude/settings.local.json` | 해당 프로젝트, 사용자만 | X (gitignore) |

### 우선순위 (높음 → 낮음)

1. **Managed** — 덮어쓸 수 없음
2. **CLI 인자** — 세션 한정
3. **Local** (`.claude/settings.local.json`)
4. **Project** (`.claude/settings.json`)
5. **User** (`~/.claude/settings.json`)

**중요**: 배열은 스코프 간 **병합**. 스칼라는 우선순위대로 덮어씀.

---

## 2. 최상위 키 전체 목록

| 키 | 타입 | 용도 |
|-----|-----|-----|
| `$schema` | string | JSON 스키마 URL (에디터 자동완성) |
| `permissions` | object | 도구 허용·차단·확인 규칙 |
| `env` | object | 환경 변수 |
| `hooks` | object | 라이프사이클 훅 (→ hooks-guide.md) |
| `model` | string | 기본 모델 |
| `effortLevel` | string | 모델 노력 수준 |
| `agent` | string | 메인 스레드로 실행할 서브에이전트 |
| `enabledPlugins` | object | 활성 플러그인 |
| `extraKnownMarketplaces` | object | 추가 플러그인 마켓플레이스 |
| `autoMode` | object | Auto 모드 환경·규칙 |
| `defaultMode` | string | 시작 시 권한 모드 |
| `sandbox` | object | 샌드박스 격리 (macOS/Linux) |
| `outputStyle` | string | 출력 스타일 |
| `language` | string | 응답 언어 |
| `autoMemoryDirectory` | string | auto-memory 저장 위치 |
| `claudeMdExcludes` | array | 제외할 CLAUDE.md 경로 (글로브) |
| `attribution` | object | 커밋/PR 서명 |
| `plansDirectory` | string | 플랜 파일 디렉토리 |
| `tui` | string | 터미널 UI 렌더러 |
| `disableAllHooks` | bool | 모든 훅 일시 비활성화 |
| `disableSkillShellExecution` | bool | 스킬 내 인라인 셸 차단 |

---

## 3. `permissions` (가장 자주 수정)

```json
{
  "permissions": {
    "allow": ["Bash(npm run lint)", "Read(~/.zshrc)"],
    "deny": ["Bash(curl *)", "Read(./.env)"],
    "ask": ["Bash(git push *)"],
    "additionalDirectories": ["../docs/", "/opt/shared"],
    "defaultMode": "acceptEdits"
  }
}
```

### 규칙 문법

| 규칙 | 효과 |
|-----|-----|
| `Bash` | 모든 bash 명령 |
| `Bash(npm run *)` | `npm run`으로 시작하는 명령 |
| `Read(./.env)` | 특정 파일 읽기 |
| `Edit(./src/*)` | 디렉토리 내 파일 편집 |
| `WebFetch(domain:example.com)` | 해당 도메인 요청 |
| `MCP(tool:filesystem)` | MCP 서버 접근 |

### 평가 순서

**deny → ask → allow**. 첫 매칭 규칙이 승리.

### `defaultMode` 옵션

- `"default"` — 매 도구마다 확인
- `"acceptEdits"` — Edit/Write 자동 승인, 나머지 확인
- `"plan"` — 플랜 모드로 시작
- `"auto"` — Auto 모드로 시작
- `"bypassPermissions"` — 모든 도구 자동 허용 (위험)

---

## 4. `env` — 환경 변수

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "FOO": "bar"
  }
}
```

시스템 환경과 병합되어 모든 bash 명령에 전달.

**사용자 자주 쓸 변수**:
- `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` — auto-memory 끄기
- `CLAUDE_CODE_NEW_INIT=1` — `/init` 대화형 모드
- `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` — `--add-dir` 디렉토리의 CLAUDE.md도 로드

---

## 5. `model` / `effortLevel` / `agent`

```json
{
  "model": "claude-sonnet-4-6",
  "effortLevel": "high",
  "agent": "code-reviewer"
}
```

| 키 | 옵션 |
|----|-----|
| `model` | `claude-opus-4-7`, `claude-sonnet-4-6`, `claude-haiku-4-5`, `haiku`, `sonnet`, `opus` |
| `effortLevel` | `low`, `medium`, `high`, `xhigh`, `max` |
| `availableModels` | 사용자가 선택 가능한 모델 제한 |
| `agent` | 메인 스레드로 실행할 서브에이전트 이름 |

---

## 6. `autoMode` — Auto 모드

```json
{
  "autoMode": {
    "environment": ["Trusted repo: github.com/mycompany/repo"],
    "allow": ["Bash(npm run test *)", "Read(src/*)"],
    "soft_deny": ["WebFetch"]
  },
  "useAutoModeDuringPlan": true,
  "disableAutoMode": "disable"
}
```

---

## 7. `sandbox` — 샌드박스 격리

macOS/Linux/WSL2에서 bash 명령을 격리된 환경에서 실행.

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["docker *"],
    "filesystem": {
      "allowWrite": ["/tmp/build", "~/.kube"],
      "denyWrite": ["/etc"],
      "denyRead": ["~/.aws/credentials"]
    },
    "network": {
      "allowedDomains": ["github.com", "*.npmjs.org"],
      "deniedDomains": ["uploads.github.com"],
      "allowUnixSockets": ["/var/run/docker.sock"]
    }
  }
}
```

---

## 8. 보안 설정

| 키 | 타입 | 설명 |
|-----|-----|-----|
| `allowManagedPermissionRulesOnly` | bool | 사용자·프로젝트 permission 규칙 무시 (Managed만 사용) |
| `disableBypassPermissionsMode` | `"disable"` | bypass 모드 진입 차단 |
| `skipDangerousModePermissionPrompt` | bool | bypass 확인 다이얼로그 스킵 |
| `disableSkillShellExecution` | bool | 스킬 내 `` !`...` `` 셸 실행 비활성화 |
| `disableAllHooks` | bool | 모든 hook 비활성화 |
| `disableAutoMode` | `"disable"` | Auto 모드 진입 차단 |

---

## 9. 플러그인 설정

```json
{
  "enabledPlugins": {
    "formatter@acme-tools": true,
    "deployer@acme-tools": true
  },
  "extraKnownMarketplaces": {
    "acme-tools": {
      "source": { "source": "github", "repo": "acme-corp/claude-plugins" }
    }
  }
}
```

### Managed 전용

| 키 | 설명 |
|----|-----|
| `strictKnownMarketplaces` | 허용할 마켓플레이스 소스 화이트리스트 |
| `blockedMarketplaces` | 차단할 소스 |
| `pluginTrustMessage` | 커스텀 경고 메시지 |

---

## 10. MCP 설정

| 키 | 범위 | 설명 |
|----|-----|-----|
| `allowedMcpServers` | Managed | 허용 MCP 서버 화이트리스트 |
| `deniedMcpServers` | Managed | 차단 서버 |
| `allowManagedMcpServersOnly` | Managed | Managed 목록만 사용 |
| `enableAllProjectMcpServers` | 모두 | 프로젝트 `.mcp.json` 자동 승인 |
| `enabledMcpjsonServers` | 모두 | 특정 서버만 활성 |
| `disabledMcpjsonServers` | 모두 | 특정 서버 비활성 |

---

## 11. Auto Memory

```json
{
  "autoMemoryDirectory": "~/my-memory-dir"
}
```

프로젝트 settings에서는 허용 안 됨 (보안: 공유 레포가 민감 경로로 redirect 방지). Policy/local/user 만 허용.

환경변수 `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`로 비활성화 가능. `/memory` 명령으로 토글.

---

## 12. 서명 / 커밋

```json
{
  "attribution": {
    "commit": "🤖 Generated with Claude Code\n\nCo-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>",
    "pr": "🤖 Generated with Claude Code"
  },
  "includeGitInstructions": false
}
```

---

## 13. 기타 유용한 설정

| 키 | 설명 | 예시 |
|----|-----|-----|
| `outputStyle` | 출력 스타일 | `"Explanatory"`, `"Concise"` |
| `language` | 응답 언어 | `"korean"`, `"japanese"` |
| `tui` | 터미널 UI | `"fullscreen"`, `"default"` |
| `viewMode` | 트랜스크립트 뷰 | `"default"`, `"verbose"`, `"focus"` |
| `showThinkingSummaries` | Extended thinking 표시 | `true` |
| `alwaysThinkingEnabled` | 기본으로 thinking 활성 | `true` |
| `plansDirectory` | 플랜 파일 저장 위치 | `"./plans"` |
| `respectGitignore` | 파일 피커에서 gitignore 존중 | `false` |
| `defaultShell` | `!` 명령 기본 셸 | `"bash"`, `"powershell"` |
| `apiKeyHelper` | API 키 생성 스크립트 | `/bin/gen-key.sh` |
| `minimumVersion` | 자동 업데이트 하한 | `"2.1.100"` |
| `autoUpdatesChannel` | 릴리즈 채널 | `"stable"`, `"latest"` |
| `claudeMdExcludes` | 무시할 CLAUDE.md 경로 | `["**/monorepo/CLAUDE.md"]` |

---

## 14. 검증과 자동 백업

### `/status` 명령

현재 활성 설정 레이어·출처·에러 표시.

### 자동 백업

Claude Code가 settings 수정 시 **타임스탬프 백업** 자동 생성. **최근 5개** 유지.

### JSON 스키마

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json"
}
```

VS Code, Cursor 등에서 자동완성 작동.

---

## 15. Managed 전용 키 (사용자는 일반적으로 미사용)

| 키 | 용도 |
|-----|-----|
| `forceLoginMethod` | 로그인 방식 고정 (`claudeai`, `console`) |
| `forceLoginOrgUUID` | 특정 조직 강제 |
| `forceRemoteSettingsRefresh` | 시작 시 원격 설정 갱신 실패 시 차단 |
| `allowedChannelPlugins` | 채널 플러그인 화이트리스트 |
| `channelsEnabled` | 채널 기능 활성 |
| `companyAnnouncements` | 시작 시 표시할 공지 |

---

## 사용자 현재 설정 관련

- `.claude/settings.json` — 프로젝트 공유
- `.claude/settings.local.json` — gitignore, 개인 권한 규칙
- `~/.claude/settings.json` — 전역 (개인 기기)
- `/tmp/` 경유 규칙(→ `reference_self_modification_policy.md`): Claude는 `~/.claude/settings.json` 직접 편집 불가. `/tmp/xxx.sh` 작성 → 사용자가 `sh /tmp/xxx.sh` 실행.

---

## 관련 문서

- `hooks-guide.md` — `hooks` 키 상세
- `claude-md-guide.md` — `claudeMdExcludes`, auto-memory와 CLAUDE.md 상호작용
- `mcp-guide.md` — MCP 서버 설정
- `skills-guide.md` — `disableSkillShellExecution`
