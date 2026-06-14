# Claude Code MCP - Source of Truth

> **Source**: [code.claude.com/docs/en/mcp](https://code.claude.com/docs/en/mcp)
> **Updated**: 2026-05-25 (guide-sync 2026-05-25 반영: 아래 🆕 블록)
> **Purpose**: MCP 서버 설정·디버깅 시 유일한 참조 문서. 사용자 gws·Gmail·Calendar·DART·Gamma 연동 관련.

---

## 🆕 2026-05-25 sync 반영

- **MCP Tool Search 기본 on** — 도구 정의를 세션 시작 시 다 안 올리고 필요 시 검색 로드. MCP 많아도 컨텍스트 부담 작음. `ENABLE_TOOL_SEARCH`(true/auto/auto:N/false)로 제어. Sonnet4+/Opus4+ 필요(Haiku 미지원). → **사용자 7개 MCP가 이미 이 덕에 컨텍스트 절약 중.**
- 서버별 `alwaysLoad: true`(.mcp.json) — 매 턴 필요한 소수 도구는 deferral 면제(상시 로드).
- **scope 명칭 변경**: `local`(기본, 예전 project) / `project`(.mcp.json 팀공유) / `user`(예전 global, 전 프로젝트).
- transport: `http`(권장, `streamable-http` alias) / `stdio` / `sse`(**deprecated**, http로 이전 권장). 사용자 stdio(DART)·claude.ai 커넥터 무관.
- `.mcp.json` 환경변수 확장 `${VAR}`·`${VAR:-default}` (command/args/env/url/headers).
- OAuth: `/mcp`로 인증, `--callback-port`·`--client-id`, `oauth.scopes`로 범위 제한, `headersHelper`로 커스텀 인증.
- 채널: 서버가 `claude/channel` 선언 + `--channels`로 외부 이벤트(텔레그램·CI·웹훅) 푸시 수신.
- 출력 한도 기본 25,000토큰(`MAX_MCP_OUTPUT_TOKENS`), 10,000 초과 시 경고.
- claude.ai 커넥터 자동 사용(구독 인증 시). `ENABLE_CLAUDEAI_MCP_SERVERS=false`로 차단.

---

## 1. MCP 개요

**MCP** (Model Context Protocol) = AI-도구 통합 오픈 스탠다드. Claude Code가 MCP 서버를 통해 외부 도구·DB·API에 직접 접근.

### 왜 쓰나

데이터를 매번 복사해서 붙여넣던 걸 MCP로 연결하면 Claude가 **직접 읽고 쓸 수 있음**. 사용자 유스케이스:
- Gmail → 메일 검색·드래프트 (`your-email@gmail.com`)
- Google Calendar → 팀 예약·일정 관리 (`your-team@gmail.com`)
- Google Docs/Sheets → gws CLI 경유
- DART → 한국주 공시 조회
- Gamma → 프레젠테이션 생성

### 할 수 있는 것

- 이슈트래커 기반 기능 구현 (JIRA ENG-4521 → PR)
- 모니터링 데이터 분석 (Sentry 에러 조회)
- DB 쿼리 (PostgreSQL 자연어)
- 디자인 통합 (Figma)
- 워크플로우 자동화 (Gmail 드래프트)
- **채널 기능**: MCP 서버가 세션에 메시지를 푸시 → Claude가 외부 이벤트(CI, 모니터링, 채팅) 반응

---

## 2. 3가지 서버 타입 (transport)

### a. HTTP (원격, 권장)

```bash
claude mcp add --transport http <name> <url>

# 예시
claude mcp add --transport http notion https://mcp.notion.com/mcp
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
```

인증 필요 시 `--header` 또는 `/mcp` 명령으로 OAuth.

### b. SSE (Server-Sent Events, **deprecated**)

```bash
claude mcp add --transport sse <name> <url>
```

HTTP로 마이그레이션 권장. 기존 SSE 서버는 작동하지만 신규 생성 비권장.

### c. stdio (로컬 프로세스)

```bash
claude mcp add [options] <name> -- <command> [args...]

# 예시
claude mcp add --transport stdio --env AIRTABLE_API_KEY=YOUR_KEY airtable \
  -- npx -y airtable-mcp-server

claude mcp add --transport stdio db \
  -- npx -y @bytebase/dbhub --dsn "postgresql://..."
```

**중요: 옵션 순서**

모든 옵션(`--transport`, `--env`, `--scope`, `--header`)은 **서버 이름 앞에**. `--` 이후가 서버에 전달될 명령·인자.

```
claude mcp add --transport stdio --env KEY=val myserver -- python server.py --port 8080
```

Windows (WSL 아닌 네이티브): `npx`는 `cmd /c` 래퍼 필요.

---

## 3. 3가지 설치 스코프

| 스코프 | 로드 위치 | 팀 공유 | 저장 위치 |
|-------|---------|--------|---------|
| **Local** (기본) | 현재 프로젝트만 | X | `~/.claude.json` |
| **Project** | 현재 프로젝트만 | O (git 커밋) | `.mcp.json` (프로젝트 루트) |
| **User** | 모든 프로젝트 | X | `~/.claude.json` |

### 스코프 지정

```bash
# Local (기본)
claude mcp add --transport http stripe https://mcp.stripe.com

# Project (팀 공유)
claude mcp add --transport http paypal --scope project https://mcp.paypal.com/mcp

# User (내 모든 프로젝트)
claude mcp add --transport http hubspot --scope user https://mcp.hubspot.com/anthropic
```

### 우선순위 (중복 정의 시)

1. Local scope
2. Project scope
3. User scope
4. Plugin 제공 서버
5. claude.ai 커넥터

스코프 셋은 **이름**으로 중복 매칭, 플러그인·커넥터는 **엔드포인트**로 매칭.

### MCP "local" ≠ 일반 settings의 "local"

헷갈리기 쉬움:
- **MCP local-scope** = `~/.claude.json` 에 저장 (홈 디렉토리)
- **일반 local settings** = `.claude/settings.local.json` (프로젝트 디렉토리)

---

## 4. 설정 파일 구조

### `~/.claude.json` (Local/User scope)

```json
{
  "projects": {
    "/path/to/your/project": {
      "mcpServers": {
        "stripe": {
          "type": "http",
          "url": "https://mcp.stripe.com"
        }
      }
    }
  }
}
```

### `.mcp.json` (Project scope, 프로젝트 루트)

```json
{
  "mcpServers": {
    "shared-server": {
      "command": "/path/to/server",
      "args": [],
      "env": {}
    }
  }
}
```

**보안**: `.mcp.json` 기반 서버는 첫 사용 시 승인 프롬프트. 초기화: `claude mcp reset-project-choices`

### 환경 변수 확장

`.mcp.json`에서 `${VAR}`·`${VAR:-default}` 지원:

```json
{
  "mcpServers": {
    "api-server": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": { "Authorization": "Bearer ${API_KEY}" }
    }
  }
}
```

확장 가능 위치: `command`, `args`, `env`, `url`, `headers`. 필수 변수 누락 시 Claude Code 파싱 실패.

---

## 5. 관리 명령

```bash
claude mcp list                # 전체 서버 조회
claude mcp get <name>          # 특정 서버 상세
claude mcp remove <name>       # 서버 제거
claude mcp reset-project-choices  # .mcp.json 승인 초기화
```

Claude Code 세션 내에서:
- `/mcp` — 서버 상태 확인, OAuth 인증

---

## 6. 인증

### OAuth 2.0

```bash
# 1. 서버 추가
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp

# 2. Claude Code 세션에서
/mcp  # → 브라우저 로그인
```

**팁**:
- 토큰 안전하게 저장, 자동 갱신
- "Clear authentication"으로 권한 철회
- 브라우저 리디렉트 실패 시 콜백 URL 수동 복사 가능

### 고정 콜백 포트

일부 서버는 사전 등록된 redirect URI 필요. `--callback-port`로 고정:

```bash
claude mcp add --transport http --callback-port 8080 my-server https://mcp.example.com/mcp
```

사전 등록 OAuth 자격증명: `--client-id` + `--client-secret` 조합 사용.

---

## 7. 동적 업데이트 & 재연결

- **동적 도구 업데이트**: MCP 서버가 `list_changed` 알림 전송 시 Claude Code가 도구·프롬프트·리소스 자동 갱신
- **자동 재연결**: HTTP/SSE 서버 세션 중 끊김 시 **5회까지** 지수 백오프 재연결 (1초→2→4→…). 5회 실패 시 failed. `/mcp`에서 수동 재시도. **stdio는 자동 재연결 안 됨**
- **채널 기능**: 서버가 `claude/channel` 기능 선언 + `--channels` 플래그로 세션 외부 이벤트를 주입

---

## 8. 플러그인 MCP

플러그인이 MCP 서버 번들 가능.

### 위치

- `.mcp.json` at plugin root
- 또는 `plugin.json` 내부에 inline

### 예시 (`.mcp.json` at plugin root)

```json
{
  "mcpServers": {
    "database-tools": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": { "DB_URL": "${DB_URL}" }
    }
  }
}
```

### 환경 변수

- `${CLAUDE_PLUGIN_ROOT}` — 번들된 플러그인 파일
- `${CLAUDE_PLUGIN_DATA}` — 플러그인 업데이트 후에도 유지되는 영속 데이터

플러그인 활성/비활성 시 `/reload-plugins`로 MCP 서버도 재시작.

---

## 9. 도구 네이밍

MCP 도구 호출 시 이름: `mcp__<server>__<tool>`

예시:
- `mcp__memory__create_entities`
- `mcp__filesystem__read_file`
- `mcp__claude_ai_Gmail__search_threads`
- `mcp__claude_ai_Google_Calendar__create_event`
- `mcp__dart-mcp__search_disclosure`

---

## 10. 성능·제한

| 설정 | 설명 | 기본 |
|------|------|-----|
| `MCP_TIMEOUT` | 서버 시작 타임아웃 (ms) | 환경변수, 예: `MCP_TIMEOUT=10000` |
| `MAX_MCP_OUTPUT_TOKENS` | 도구 출력 토큰 제한 | 10,000 (초과 시 경고) |

```bash
MCP_TIMEOUT=10000 claude  # 10초 타임아웃
MAX_MCP_OUTPUT_TOKENS=50000 claude  # 출력 제한 50K
```

---

## 11. settings.json에서 MCP 제어

| 키 | 범위 | 설명 |
|-----|-----|-----|
| `allowedMcpServers` | Managed | 허용 서버 화이트리스트 |
| `deniedMcpServers` | Managed | 차단 서버 |
| `allowManagedMcpServersOnly` | Managed | Managed 목록만 사용 |
| `enableAllProjectMcpServers` | 모두 | 프로젝트 `.mcp.json` 자동 승인 |
| `enabledMcpjsonServers` | 모두 | 특정 서버만 활성 |
| `disabledMcpjsonServers` | 모두 | 특정 서버 비활성 |

→ settings-guide.md MCP 섹션 참조.

---

## 12. 보안 주의

- **제3자 MCP 서버는 사용자 책임**. Anthropic이 모든 서버를 검증하지 않음.
- 외부 컨텐츠 가져오는 서버는 **프롬프트 인젝션 리스크** 특히 주의
- OAuth 토큰은 안전하게 저장되지만, 공유 기기 주의
- `.mcp.json` 커밋 시 민감 키가 env 확장으로 분리돼 있는지 확인
- Managed 환경에서는 `strictKnownMarketplaces` 같이 플러그인 MCP도 화이트리스트 가능

---

## 사용자 현재 MCP 연동

| 서비스 | 계정 | 주요 도구 |
|--------|------|-----------|
| Gmail | your-email | `mcp__claude_ai_Gmail__*` |
| Google Calendar | your-email + your-team | `mcp__claude_ai_Google_Calendar__*` |
| Google Drive | — | `mcp__claude_ai_Google_Drive__*` |
| Gamma | — | `mcp__claude_ai_Gamma__*` |
| DART | 한국 공시 | `mcp__dart-mcp__*` |
| gws CLI | your-email + your-team | **MCP 아닌 CLI** (Google Docs/Sheets/Gmail/Calendar 보완) |

**우선순위 규칙** (→ `feedback_gws_first.md` 메모리):
Google 서비스 접근은 **gws CLI 1순위**. WebFetch 이전에, 붙여넣기 요청 이전에 `gws` 먼저 시도.

---

## 관련 문서

- `settings-guide.md` — MCP 관련 settings.json 키
- `plugins-guide.md` — 플러그인 번들 MCP
- `hooks-guide.md` — MCP 도구 Hook 매칭 (`mcp__.*`)
