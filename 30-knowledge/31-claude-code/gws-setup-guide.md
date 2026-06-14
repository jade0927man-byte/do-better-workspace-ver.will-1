# gws (Google Workspace CLI) 설치 가이드

> Claude Code에서 Gmail 발송, Calendar, Drive, Sheets 등을 직접 사용하기 위한 설정 가이드

## gws란?

Google Workspace 팀이 만든 CLI 도구. Google Discovery Service를 런타임에 읽어 커맨드를 동적 생성하므로, Google이 API를 추가하면 자동으로 반영된다.

**지원 서비스**: Gmail, Calendar, Drive, Docs, Sheets, Slides, Chat, Forms, Tasks, People, Groups, Admin, Meet, Apps Script 등

**핵심 장점**:
- `gws mcp` 명령으로 MCP 서버 내장 → Claude Code에서 바로 사용
- `gws gmail +send`로 메일 직접 발송 (드래프트가 아닌 진짜 발송)
- npm 한 줄로 설치

---

## 1단계: 설치

### 필수 조건
- Node.js 18 이상 (`node --version`으로 확인)

### Mac
```bash
sudo npm install -g @googleworkspace/cli
```

### 설치 확인
```bash
gws --version
```

---

## 2단계: Google Cloud 프로젝트 설정

### 방법 A: 자동 설정 (gcloud CLI 필요 — 권장)

gcloud CLI가 없으면 먼저 설치:
```bash
brew install --cask google-cloud-sdk
```

그 다음 한 줄로 끝:
```bash
gws auth setup
```

이 명령어가 자동으로:
- Cloud 프로젝트 생성
- 필요한 API 활성화 (Gmail, Calendar, Drive 등 12개)
- OAuth 동의 화면 설정
- 자격증명 생성

#### setup 중 수동 작업이 필요한 부분

`gws auth setup` 5/5 단계에서 OAuth 자격증명 수동 입력을 요구할 수 있다:

1. **Step A — OAuth 동의 화면 설정**:
   - 터미널에 나온 링크 클릭 → Google Cloud Console 열림
   - 앱 이름: `gws-cli`
   - 사용자 지원 이메일: 본인 이메일 선택
   - User Type: **외부** 선택
   - 쭉 다음/만들기로 넘기기
   - **대상 → 테스트 사용자**에 본인 Gmail 추가

2. **Step B — OAuth 클라이언트 생성**:
   - 터미널에 나온 링크 클릭
   - **OAuth 클라이언트 만들기** 버튼 클릭
   - 애플리케이션 유형: **데스크톱 앱**
   - 이름: `gws-cli`
   - 만들기 클릭
   - **클라이언트 ID** 복사 → 터미널에 붙여넣기 → Enter
   - **클라이언트 보안 비밀번호(GOCSPX-...)** 복사 → 터미널에 붙여넣기 → Enter
   - (클라이언트 보안 비밀번호는 왼쪽 메뉴 "클라이언트" → 방금 만든 항목 클릭하면 보임)

3. **OAuth scope 선택**:
   - `Recommended (Core Consumer Scopes)` 체크 → Enter

4. **브라우저 인증**:
   - 터미널에 나온 URL을 브라우저에서 열기
   - Google 계정 로그인 → 권한 승인
   - "창을 닫으세요" 나오면 완료

### 방법 B: 수동 설정 (gcloud 없이)

1. [Google Cloud Console](https://console.cloud.google.com) 접속
2. 프로젝트 생성 (예: `my-workspace-cli`)
3. 필요한 API 활성화:

| 서비스 | 활성화 링크 |
|--------|-----------|
| Gmail | https://console.cloud.google.com/apis/api/gmail.googleapis.com |
| Calendar | https://console.cloud.google.com/apis/api/calendar-json.googleapis.com |
| Drive | https://console.cloud.google.com/apis/api/drive.googleapis.com |
| Sheets | https://console.cloud.google.com/apis/api/sheets.googleapis.com |

4. OAuth 동의 화면 설정 (위 Step A 참고)
5. OAuth 자격증명 생성 (위 Step B 참고)
6. JSON 다운로드 → `~/.config/gws/client_secret.json`에 복사:
```bash
mkdir -p ~/.config/gws
cp ~/Downloads/client_secret_xxxxx.json ~/.config/gws/client_secret.json
```
7. 로그인:
```bash
gws auth login
```

---

## 3단계: 인증 확인

```bash
# Gmail 테스트
gws gmail +triage

# Calendar 테스트
gws calendar +agenda

# Drive 테스트
gws drive files list --params '{"pageSize": 1}'
```

---

## 4단계: Claude Code에서 MCP 서버로 연동

프로젝트 루트에 `.mcp.json` 생성:

```json
{
  "mcpServers": {
    "gws": {
      "command": "gws",
      "args": ["mcp", "-s", "gmail,calendar,drive,sheets"]
    }
  }
}
```

> `-s all`은 도구가 수백 개가 되어 MCP 클라이언트 한계를 초과할 수 있으므로, 사용할 서비스만 지정한다.

| 용도 | `-s` 값 |
|------|---------|
| 기본 업무 | `gmail,calendar,drive` |
| 데이터 분석 | `sheets,drive` |
| 전체 업무 | `gmail,calendar,drive,sheets,docs,tasks` |

---

## 자주 쓰는 명령어

### Gmail
```bash
# 메일 보내기
gws gmail +send --to recipient@gmail.com --subject "제목" --body "내용"

# 미읽은 메일 요약
gws gmail +triage

# 메일 답장
gws gmail +reply --message-id MESSAGE_ID --body "답장 내용"
```

### Calendar
```bash
# 오늘 일정
gws calendar +agenda

# 일정 추가
gws calendar +insert --summary "미팅" --start "2026-03-29T14:00:00"
```

### Drive
```bash
# 파일 업로드
gws drive +upload ./report.pdf --name "Q1 Report"

# 파일 목록
gws drive files list --params '{"pageSize": 10}'
```

---

## 보안 주의사항

- `client_secret*.json` 파일은 절대 git에 커밋하지 않는다
- `.gitignore`에 추가:
```
client_secret*.json
credentials.json
.encryption_key
.env
```

---

## 문제 해결

### "gws" 명령어를 찾을 수 없음
```bash
# npm 글로벌 설치 경로 확인
npm root -g
# PATH에 추가
export PATH="$(npm prefix -g)/bin:$PATH"
```

### 인증 실패 / 403 에러
- API가 활성화되었는지 확인
- 테스트 사용자에 이메일이 등록되었는지 확인
- 재인증: `gws auth login`

### "Access blocked: This app's request is invalid"
- OAuth 동의 화면에서 **테스트 사용자**에 본인 이메일을 추가했는지 확인

---

## 멀티 계정 (두 번째 Gmail 연동)

하나의 gws 설치로 여러 Google 계정을 사용할 수 있다.

### 설정 방법

1. **GCP 테스트 사용자 추가**: Google Cloud Console → 대상 → 테스트 사용자에 두 번째 이메일 추가
2. **두 번째 계정으로 로그인 + 자격증명 내보내기**:
```bash
gws auth login  # 두 번째 계정으로 로그인
gws auth export --unmasked > ~/.config/gws/credentials-second.json
gws auth login  # 다시 기본 계정으로 로그인
```
3. **환경변수로 계정 전환**:
```bash
# 기본 계정 (자동)
gws gmail +triage

# 두 번째 계정
GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=~/.config/gws/credentials-second.json gws gmail +triage
```

### Claude Code에서 MCP 서버 2개 등록 (추천)

`.mcp.json`에 계정별 MCP 서버를 등록하면 Claude Code에서 두 계정을 **동시에** 사용할 수 있다:

```json
{
  "mcpServers": {
    "gws": {
      "command": "gws",
      "args": ["mcp", "-s", "gmail,calendar,drive,sheets"]
    },
    "gws-second": {
      "command": "gws",
      "args": ["mcp", "-s", "gmail,calendar"],
      "env": {
        "GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE": "/Users/USERNAME/.config/gws/credentials-second.json"
      }
    }
  }
}
```

이렇게 하면:
- `gws` 서버 → 기본 계정 (개인)
- `gws-second` 서버 → 두 번째 계정 (업무 등)
- Claude Code 재시작 후 두 계정 도구가 동시에 활성화

스킬이나 Bash에서 직접 호출할 때는 환경변수를 앞에 붙여서 사용:
```bash
GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=~/.config/gws/credentials-second.json \
  gws gmail +send --to someone@gmail.com --subject "제목" --body "내용"
```

### 주의: 자격증명 export 시 stderr 오염

`gws auth export`는 stderr로 `Using keyring backend: keyring`을 출력하는데, 이게 파일에 섞이면 JSON이 깨진다. 반드시 확인:
```bash
head -1 ~/.config/gws/credentials-second.json
# "{" 이 아니면 첫 줄 제거:
tail -n +2 ~/.config/gws/credentials-second.json > /tmp/clean.json && mv /tmp/clean.json ~/.config/gws/credentials-second.json
```

### "다른 주소에서 메일 보내기" (발송만, 읽기 불가)

Gmail 설정 → 계정 및 가져오기 → "다른 주소에서 메일 보내기"에 두 번째 이메일을 추가하면, 별도 인증 없이 `--from second@gmail.com`으로 발송 가능. 단, 메일 읽기는 불가하므로 멀티계정 방식을 추천.

---

## 참고 링크

- GitHub: https://github.com/googleworkspace/cli
- npm: https://www.npmjs.com/package/@googleworkspace/cli
