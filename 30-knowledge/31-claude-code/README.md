# 31 Claude Code 가이드

**Claude Code 전용 자료 허브** — 공식 문서 레퍼런스 + 실습 가이드 + 작성 베스트 프랙티스.

`.claude/` 폴더(실행 파일: agents/commands/skills/hooks)를 **어떻게 설계·작성할지** 참조하는 문서들이 여기 모입니다. 실제 실행은 `.claude/`에서, 원리·원칙·패턴은 여기에서.

> 이 폴더는 Anthropic 공식 문서를 한국어로 정리한 레퍼런스입니다. Claude Code 버전 업 시 갱신하세요.

## 가이드 목록

### 공식 문서 레퍼런스 (Source of Truth)
| 파일 | 용도 | 언제 참조? |
|------|------|-----------|
| [claude-md-guide.md](claude-md-guide.md) | CLAUDE.md 로딩 순서·계층 구조·최적화 | CLAUDE.md 수정 시 |
| [skills-guide.md](skills-guide.md) | Skills 구조(SKILL.md, frontmatter, 로딩, description) | 스킬 생성/수정 시 |
| [subagents-guide.md](subagents-guide.md) | Subagent 작성 (`.claude/agents/`) | 서브에이전트 생성/수정 시 |
| [rules-guide.md](rules-guide.md) | `.claude/rules/` 시스템, 조건부 규칙 | 규칙 파일 생성/수정 시 |
| [plugins-guide.md](plugins-guide.md) | Plugin 개발/설치/관리 | 플러그인 작업 시 |
| [hooks-guide.md](hooks-guide.md) | Hook 설계 (SessionStart, PreToolUse 등) | `settings.json` hooks 블록 설계 시 |
| [settings-guide.md](settings-guide.md) | `settings.json` 구조 (permissions, env, sandbox) | settings 수정 시 |
| [mcp-guide.md](mcp-guide.md) | MCP 서버 설정·디버깅 (`.mcp.json`) | MCP 추가·디버깅 시 |

### 작성 원칙·실습
| 파일 | 용도 | 언제 참조? |
|------|------|-----------|
| [claude-md-best-practices.md](claude-md-best-practices.md) | CLAUDE.md 작성 베스트 프랙티스 (길이·지시사항 수·Progressive Disclosure) | CLAUDE.md 개선 시 |
| [prompt-engineering-guide.md](prompt-engineering-guide.md) | 프롬프트 설계 원칙 (Few-shot > 규칙 나열 등) | 스킬·커맨드·에이전트 생성·개선 시 |
| [practice-guide.md](practice-guide.md) | Claude Code 실습 가이드 (설치·클론·첫 실행) | 새 환경 설정·온보딩 시 |

### 외부 연동
| 파일 | 용도 | 언제 참조? |
|------|------|-----------|
| [gws-setup-guide.md](gws-setup-guide.md) | gws CLI 설치 및 Google Workspace 연동 | gws 재설정/트러블슈팅 시 |

## 관계도

```
CLAUDE.md (프로젝트 규칙, 항상 로드)
  ├── rules/    (조건부 규칙, 파일 편집 시 자동 로드)
  ├── skills/   (모듈형 기능 확장, 자동/수동 트리거)
  │   └── agents (서브에이전트, 독립 컨텍스트)
  └── plugins/  (외부 패키지로 skills/commands 번들)

gws → Skills에서 Google API 호출 시 필요한 CLI 도구
```

## 사용법

CLAUDE.md의 "주요 가이드 (자동 참조)" 테이블이 이 폴더의 각 가이드를 트리거와 연결합니다.
예: "스킬 만들어줘"라고 하면 Claude가 먼저 `skills-guide.md`를 읽고 원칙을 적용합니다.
