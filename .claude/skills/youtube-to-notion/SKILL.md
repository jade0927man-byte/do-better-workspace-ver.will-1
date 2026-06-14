---
name: youtube-to-notion
description: YouTube URL을 받아 영상 내용을 분석하고 핵심 인사이트, 활용 방안, 검증 필요 사항을 정리한 뒤 노션 YouTube 인사이트 라이브러리 DB에 저장. "유튜브 저장", "유튜브 분석", "youtube-to-notion", YouTube URL이 주어질 때 사용.
argument-hint: <YouTube URL>
disable-model-invocation: true
allowed-tools: Bash, Read
---

# YouTube → Notion 인사이트 저장

YouTube URL을 분석하고 당신의 노션 "YouTube 인사이트 라이브러리" DB에 저장합니다.

## 설정값

- **Notion DB ID**: `YOUR_NOTION_DB_ID`
- **notion_api.py 경로**: `${CLAUDE_SKILL_DIR}/../notion-handler/scripts/notion_api.py`
- **트랜스크립트 스크립트**: `${CLAUDE_SKILL_DIR}/scripts/get_transcript.py`

## 실행 단계

### Step 1. 트랜스크립트 추출

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/get_transcript.py "$ARGUMENTS"
```

결과 JSON에서 다음을 확인:
- `transcript`: 자막 텍스트 (없으면 error 메시지 표시 후 중단)
- `duration`: 영상 길이
- `url`: 정규화된 YouTube URL

### Step 2. 영상 메타데이터 수집 (웹 검색)

YouTube URL에서 다음 정보를 파악:
- **영상 제목** (정확히)
- **채널명**
- **카테고리** 분류: 비즈니스/경영, 공간/부동산, 마케팅/브랜딩, 재무/투자, 조직/인사, 자동화/기술, 라이프스타일, 기타

### Step 3. 트랜스크립트 분석

아래 분석 프레임워크로 내용을 분석하세요. **당신의 사업 맥락**(전역 `~/.claude/CLAUDE.md` 또는 워크스페이스 `CLAUDE.md`에 적힌 본인 역할·사업·관심사)을 항상 고려하세요.

#### 분석 항목

**[핵심 한줄]** — 영상 전체를 한 문장으로 압축

**[핵심 인사이트]** (3~7개)
- 각 인사이트: 번호 + 제목 + 2~3줄 설명
- 구체적인 수치, 사례, 개념 포함

**[활용 방안]**
- 당신 사업/업무에 바로 적용 가능한 것
- 중장기적으로 참고할 것
- 구체적인 액션 아이템 (동사로 시작, 실행 가능하게)

**[검증 필요 & 주의사항]**
- 이 콘텐츠 제작자의 주장 중 과장되거나 확인이 필요한 것
- 당신 상황에 맞지 않을 수 있는 조언
- 한국 시장/법규와 다를 수 있는 내용

**[태그]** — 전략, 운영, 콘텐츠, 고객경험, 수익화, 리더십, 자동화, 트렌드 중 해당하는 것

**[적용 프로젝트]** — 당신의 활성 프로젝트 중 해당하는 것

**[활용도]** — 즉시 적용 / 참고용 / 아카이브

### Step 4. 노션에 저장

#### 4-1. DB 항목 생성

```bash
python3 ${CLAUDE_SKILL_DIR}/../notion-handler/scripts/notion_api.py create-page \
  --parent "YOUR_NOTION_DB_ID" \
  --properties '{
    "제목": "<영상 제목>",
    "URL": "<YouTube URL>",
    "채널명": "<채널명>",
    "카테고리": "<카테고리>",
    "태그": [<태그 배열>],
    "핵심 한줄": "<핵심 한줄>",
    "영상 길이": "<영상 길이>",
    "시청일": "<오늘 날짜 YYYY-MM-DD>",
    "활용도": "<활용도>",
    "액션 아이템": "<액션 아이템 줄바꿈으로 구분>",
    "적용 프로젝트": [<적용 프로젝트 배열>]
  }'
```

생성된 페이지 ID를 저장.

#### 4-2. 페이지 본문에 상세 분석 추가

```bash
python3 ${CLAUDE_SKILL_DIR}/../notion-handler/scripts/notion_api.py append-blocks \
  --id "<생성된 PAGE_ID>" \
  --blocks '<아래 블록 구조>'
```

**본문 블록 구조 (순서대로 작성):**

```
[섹션 1] 3줄 요약
- heading_2: "3줄 요약"
- callout (1️⃣): 첫 번째 핵심 — 무슨 일이 있었는지 (결과 중심)
- callout (2️⃣): 두 번째 핵심 — 전환점이 무엇이었는지
- callout (3️⃣): 세 번째 핵심 — 시사점/교훈 한 줄
- divider

[섹션 2] 보고서 (한 페이지 분량)
- heading_2: "보고서: [영상 제목] 전문 분석"
- heading_3: "배경"
  - paragraph: 영상 주제의 맥락과 출발점 (2~3문단, 각 paragraph 블록으로 분리)
- heading_3: "전환점 1: [제목]"
  - paragraph: 구체적 사건, 수치, 인물의 결정과 이유
- heading_3: "전환점 2: [제목]" (필요시)
  - paragraph: ...
- heading_3: "핵심 메시지"
  - paragraph: 영상이 말하고자 하는 본질적 결론
- divider

[섹션 3] 당신 사업에 주는 인사이트
- heading_2: "당신 사업에 주는 인사이트"
- heading_3: "즉시 활용"
  - callout (⚡): 당신 사업/업무에 바로 적용 가능한 것 (구체적 액션 포함)
  - callout (⚡): 두 번째 즉시 액션
- heading_3: "중장기 참고"
  - callout (📌): 6개월~1년 시야로 참고할 것
- divider

[섹션 4] 검증 필요 & 주의사항
- heading_2: "검증 필요 & 주의사항"
- callout (⚠️): 과장된 주장, 확인 필요한 수치, 한국 상황과 다른 점, 당신 상황에 안 맞는 조언
- divider

[섹션 5] 원문 핵심 발언
- heading_2: "원문 핵심 발언"
- quote: 가장 임팩트 있는 발언 (최소 2개, 최대 4개)
```

**중요 제약사항:**
- Notion rich_text는 블록당 2000자 제한 → 긴 문단은 여러 paragraph 블록으로 분리
- 보고서 paragraph는 블록 하나당 최대 500자로 유지
- 전체 블록 수가 많을 경우 50개씩 나눠서 API 호출

### Step 5. 결과 보고

저장 완료 후 사용자에게 다음을 출력:

```
✅ 노션에 저장 완료!

📹 [영상 제목]
👤 채널: [채널명] | ⏱ [영상 길이]

💡 핵심 한줄:
"[핵심 한줄]"

🔑 핵심 인사이트 [N]개:
1. [인사이트 제목]
2. [인사이트 제목]
...

⚡ 바로 해볼 것:
- [액션 아이템]

⚠️ 주의사항:
- [검증 필요 항목]

🔗 노션 링크: https://notion.so/[PAGE_ID]
```

## 오류 처리

- **자막 없음**: "이 영상은 자막이 없어 분석이 어렵습니다. 영상 URL을 확인하거나 다른 방법을 시도해주세요." 출력
- **Notion 저장 실패**: 분석 결과를 대화창에 출력하고 수동 저장 안내
- **영어 자막만 있을 경우**: 영어로 분석 후 한국어로 보고

## 주의사항

- 분석은 반드시 **당신의 사업 맥락**에 맞게 커스터마이즈
- "검증 필요" 섹션은 빠뜨리지 말 것 — 비판적 시각이 핵심
- 액션 아이템은 구체적이고 실행 가능하게 (모호한 표현 금지)
