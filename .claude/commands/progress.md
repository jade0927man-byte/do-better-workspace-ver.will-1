---
description: 영역별 진척 스냅샷에 한 줄 기록 + Daily Note에 자동 링크
argument-hint: [영역키워드] [한 줄 메모]
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

사용자의 영역별 **진척 스냅샷**(`progress/`)에 한 줄 기록을 추가합니다. 스키마는 `00-system/03-guides/progress-schema-policy.md` 참조.

**입력**: $ARGUMENTS

## `logs/` vs `progress/`

- `logs/` = **1차 원본 기록물** (카톡·이슈·거래 근거 등 영역별 원본). 이 커맨드는 **건드리지 않음**.
- `progress/` = **진척 스냅샷** (`/daily-note`·`/progress`가 생성). 이 커맨드의 기록 대상.

## 수행할 작업

### 1. 영역 판단

영역 키워드 → 폴더 매핑:

| 키워드 | 폴더 |
|--------|------|
| `workspace` | `00-system/progress/` (도구·설정 튜닝 등 메타 작업) |
| `projects` | `10-projects/{프로젝트}/progress/` (시한부 프로젝트별) |
| `operations` | `20-operations/{영역}/progress/` (지속 운영 업무별) |
| `personal` | `40-personal/progress/` (마음챙김·개인 성장 성찰만) |

> 📝 본인 사업/프로젝트 영역은 위 표에 행을 추가하세요. (예: `cafe | 20-operations/{cafe}/progress/`)

**판단 순서**:
1. $ARGUMENTS 첫 토큰이 위 키워드면 → 그 영역 확정
2. 아니면 현재 대화 맥락에서 가장 최근에 언급된 프로젝트·영역 추론
3. 모호하면 `AskUserQuestion`으로 2~3개 후보 제시 (자동 추측 금지)

### 2. 파일 경로

- 기본: `{area_folder}/YYYY-MM-DD.md`

### 3. 태그 자동 제안

메모 내용 스캔:
- "결정/합의/OK/확정/승인" → `[결정]`
- "문제/에러/이슈/막힘/실패" → `[이슈]`
- "회의/미팅/통화/콜" → `[미팅]`
- "확인/검증/재확인" → `[확인]`
- 기본값 → `[진척]`

### 4. 파일 생성 또는 append

**파일 없을 때** — 스키마 기반 신규 생성:

```markdown
---
date: YYYY-MM-DD
area: {영역키워드}
tags: [{제안태그}]
participants: [사용자]
---

# YYYY-MM-DD {영역} 진척

## 요약
- {한 줄 메모}

## 상세
### {HH:MM}
- {한 줄 메모}

## 결정 · 액션
- [{제안태그}] {한 줄 메모}

## 다음
-
```

**파일 있을 때** — `## 상세` 섹션 끝에 다음 항목 append:

```markdown
### {HH:MM} (또는 이벤트 키워드)
- [{제안태그}] {한 줄 메모}
```

그리고 front-matter `tags`에 새 태그가 없으면 추가.

### 5. Daily Note 링크 첨부

대상 파일: `40-personal/41-daily/YYYY-MM/YYYY-MM-DD.md`

- 파일 없으면 건너뛰기 (Daily Note 생성은 `/daily-note` 커맨드 담당)
- 파일 있으면:
  1. `## 오늘의 진척` 섹션 찾기
  2. 섹션 없으면 파일 마지막 `## 🔗 관련 링크` 섹션 바로 위에 `## 오늘의 진척` 신설
  3. 해당 영역 링크가 이미 있으면 append 생략, 없으면 `- [{영역}]({상대경로})` append
  4. 상대경로는 Daily Note 위치 기준 (예: `../../../10-projects/11-consulting/progress/2026-04-19.md`)

### 6. 투자 영역 `[결정]` 추가 체크

영역이 `investment` + 제안 태그가 `[결정]`이면 실행 직전 1회 확인:
> "이 결정을 `20-operations/23-investment/portfolio/decisions.md`에도 append할까요?"

Yes → 해당 파일 결정 블록에도 1줄 추가.

### 7. 결과 보고

사용자에게 결과 요약:
- 생성/수정된 파일 경로
- 태그
- Daily Note 링크 추가 여부
- (투자 영역) `decisions.md` 반영 여부

## 규칙

- 시각은 현재 시각(KST) 기준 `HH:MM` 자동 기입
- 한 줄 메모가 너무 길면(200자+) "## 상세"에 그대로 넣되 "## 요약"에는 앞부분 요약
- 인자 없이 `/progress` 실행하면: 최근 대화 핵심을 1~2줄로 요약해 제안하고 `AskUserQuestion`으로 영역·태그 확정
- 영역 키워드가 틀렸을 가능성이 있으면(예: `/progress sanno`) 가장 가까운 키워드 제안하고 확인
- **각 영역 `logs/` 폴더는 절대 건드리지 않음** — 원본 아카이브 보존

## `/daily-note`와의 역할 구분

| 상황 | 커맨드 |
|------|--------|
| 방금 막 결정된 사안을 **즉시 한 줄** 남기고 싶을 때 | `/progress {영역} {메모}` |
| 대화 클리어 전 **한 번에 여러 영역** 업데이트하고 싶을 때 | `/daily-note` 업데이트 (미리보기 + 일괄 분배) |

사용자의 주된 워크플로우는 후자. `/progress`는 대화 중 "이건 놓치면 안 돼" 순간의 단발 기록용.
