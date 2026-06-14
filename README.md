# Do Better Workspace

Claude Code 기반의 개인 생산성 워크스페이스 템플릿입니다.

비개발자도 Claude Code를 활용해 업무 관리, 프로젝트 문서화, 아이디어 정리, 자동화를 할 수 있도록 설계되었습니다.

---

## 구조

```
00-inbox/       빠른 캡처 (임시 보관)
00-system/      템플릿, 가이드, 설정
10-projects/    활성 프로젝트
20-operations/  지속적 운영 업무
30-knowledge/   지식 아카이브
40-personal/    Daily Note, Todos, 투자분석, 아이디어
50-resources/   참고 자료
90-archive/     완료된 프로젝트
```

[Johnny Decimal](00-system/04-docs/johnny-decimal-guide.md) 체계로 모든 파일을 구조화합니다.

---

## 즉시 사용 가능한 기능

| 커맨드 | 설명 |
|--------|------|
| `/daily-note` | 오늘 Daily Note 생성/열기 |
| `/thinking-partner` | 소크라테스식 생각 정리 파트너 |
| `/todos` | 전체 할 일 모아보기 |
| `/progress` | 영역별 진척 스냅샷에 한 줄 기록 |
| `/create-command` | 나만의 커맨드 만들기 |
| `/setup-workspace` | 초기 설정 마법사 |

## 설정 후 사용 가능한 기능

API 키 또는 MCP 연동이 필요합니다.

| 기능 | 필요 설정 |
|------|----------|
| 녹음/강의 정리 | 없음 (텍스트 파일만 필요) |
| 웹 크롤링 + OCR | Firecrawl + Gemini API 키 |
| Notion 연동 | Notion API 토큰 |
| 엑셀 분석 | Python + openpyxl |
| 대시보드 PRD 생성 | 없음 |

---

## 빠른 시작

1. **"Use this template"** 버튼 클릭 → 내 리포 생성
2. 로컬에 클론
3. Claude Code에서 폴더 열기
4. `/setup-workspace` 실행 — CLAUDE.md 자동 생성

자세한 설정은 [SETUP.md](SETUP.md)를 참고하세요.

---

## 포함된 가이드

- [CLAUDE.md 작성 모범사례](00-system/03-guides/CLAUDE-MD-BEST-PRACTICES.md)
- [프롬프트 엔지니어링 가이드](00-system/03-guides/PROMPT-ENGINEERING-GUIDE.md)
- [TODO 시스템 가이드](00-system/03-guides/TODO-SYSTEM-GUIDE.md)
- [Johnny Decimal 가이드](00-system/04-docs/johnny-decimal-guide.md)

---

## 라이선스

MIT
