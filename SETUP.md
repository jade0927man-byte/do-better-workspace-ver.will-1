# 설정 가이드

## 1단계: 리포지토리 복제 (2분)

1. GitHub에서 **"Use this template"** 버튼 클릭
2. 리포 이름 입력 (예: `my-workspace`)
3. 로컬에 클론:
   ```bash
   git clone https://github.com/내계정/my-workspace.git
   cd my-workspace
   ```

---

## 2단계: 초기 설정 (5분)

1. Claude Code에서 폴더 열기
2. `/setup-workspace` 입력
3. 질문에 답하면 **CLAUDE.md가 자동 생성**됩니다

> CLAUDE.md는 Claude가 프로젝트 맥락을 이해하는 핵심 파일입니다.
> 수동으로 만들려면 `CLAUDE.md.template`을 참고하세요.

---

## 3단계: 환경변수 설정 (선택)

API 연동이 필요한 스킬을 쓰려면:

```bash
cp .env.template .env
```

`.env` 파일을 열고 필요한 API 키만 입력하세요.

| 변수 | 용도 | 필수 여부 |
|------|------|----------|
| `GEMINI_API_KEY` | 웹 크롤링 이미지 OCR | 선택 |
| `FIRECRAWL_API_KEY` | 웹 크롤링 텍스트 추출 | 선택 |
| `NOTION_TOKEN` | Notion 연동 | 선택 |
| `TELEGRAM_BOT_TOKEN` | 텔레그램 봇 | 선택 |

---

## 4단계: MCP 설정 (선택)

Google Calendar, Gmail 등을 연동하려면:

```bash
cp .mcp.json.example .mcp.json
```

사용할 서비스에 맞게 `.mcp.json`을 수정하세요.

---

## 5단계: 자동 백업 설정 (선택)

매일 자동으로 git 커밋+푸시하려면:

```bash
chmod +x .scripts/daily-backup.sh
```

cron 또는 launchd에 등록하세요:
```bash
# cron 예시 (매일 23:50)
crontab -e
50 23 * * * /path/to/workspace/.scripts/daily-backup.sh
```

---

## 즉시 사용 가능

설정 없이 바로 쓸 수 있는 커맨드:

- `/daily-note` — Daily Note 생성
- `/thinking-partner` — 생각 정리
- `/todos` — 할 일 관리
- `/progress` — 영역별 진척 기록
- `/create-command` — 나만의 커맨드 만들기

---

## 문제가 있으면

- CLAUDE.md 재생성: `/setup-workspace` 다시 실행
- 가이드 참고: `00-system/03-guides/` 폴더
