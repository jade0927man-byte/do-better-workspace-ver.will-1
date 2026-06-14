# 텔레그램 인박스 봇 설정 가이드

## 1. BotFather에서 봇 생성

1. 텔레그램에서 [@BotFather](https://t.me/BotFather) 검색 → 대화 시작
2. `/newbot` 입력
3. 봇 이름 입력: `내 인박스` (원하는 이름)
4. 봇 사용자명 입력: `my_inbox_bot` (끝이 `bot`으로 끝나야 함)
5. 토큰을 받으면 복사해둠 (형식: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz1234567`)

## 2. Chat ID 확인

1. 텔레그램에서 방금 만든 봇을 찾아 아무 메시지 전송
2. 브라우저에서 열기:
   ```
   https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
   ```
3. 응답에서 `"chat":{"id": 123456789}` 에 있는 숫자가 Chat ID

## 3. .env 설정

```bash
cd /path/to/your-workspace
cp .env.template .env  # 이미 있으면 스킵
```

`.env` 파일에서 아래 값 입력:
```
TELEGRAM_BOT_TOKEN=<BotFather에서 받은 토큰>
TELEGRAM_CHAT_ID=<위에서 확인한 Chat ID>
```

## 4. 의존성 설치

```bash
pip3 install -r .claude/skills/telegram-inbox/scripts/requirements.txt
```

## 5. 봇 실행

### 수동 실행 (테스트용)
```bash
cd /path/to/your-workspace
python3 .claude/skills/telegram-inbox/scripts/telegram_bot.py
```

### 자동 실행 (launchd)
```bash
cp 00-system/02-scripts/com.dobetter.telegram-inbox.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.dobetter.telegram-inbox.plist
```

### 서비스 관리
```bash
# 상태 확인
launchctl list | grep telegram

# 중지
launchctl unload ~/Library/LaunchAgents/com.dobetter.telegram-inbox.plist

# 로그 확인
tail -f ~/Library/Logs/telegram-inbox.log
```

## 6. 사용법

봇에게 보내면 자동으로 Google Sheets에 저장됩니다:

| 보내는 것 | 분류 | 예시 |
|-----------|------|------|
| 링크 | `link` | https://example.com |
| 메모 | `note` | 내일 미팅 준비할 것 |
| `#idea` 로 시작 | `idea` | #idea 로비에 북카페 넣으면 어떨까 |
| 이미지 | `image` | 사진 첨부 |
| 파일 | `file` | PDF, 문서 등 |
| 포워딩 | `forwarded` | 다른 채팅에서 전달 |

해시태그 사용: `#프로젝트 #마케팅` → 자동으로 tags에 추가
