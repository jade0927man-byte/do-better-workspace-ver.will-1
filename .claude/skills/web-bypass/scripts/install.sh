#!/usr/bin/env bash
# web-bypass 의존성 설치 (사용자 수동 실행)
#
# 사용법:
#   bash scripts/install.sh                    # venv + curl_cffi/bs4/pyyaml만
#   bash scripts/install.sh --with-playwright  # 위 + Playwright Chromium (~300MB)
#
# 멱등성: 기존 venv가 있으면 재생성하지 않고 pip install --upgrade만 수행.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$SKILL_DIR/scripts"
VENV_DIR="$SCRIPTS_DIR/venv"
REQ_FILE="$SCRIPTS_DIR/requirements.txt"

WITH_PLAYWRIGHT=0
for arg in "$@"; do
  case "$arg" in
    --with-playwright) WITH_PLAYWRIGHT=1 ;;
    -h|--help)
      sed -n '2,9p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "알 수 없는 옵션: $arg" >&2
      exit 2
      ;;
  esac
done

# 라이선스 가드 (vendoring 표기 누락 방지)
if [ ! -f "$SKILL_DIR/LICENSE" ]; then
  echo "ERROR: $SKILL_DIR/LICENSE 누락. vendoring 출처 확인 필요." >&2
  exit 1
fi

# venv 생성 (없을 때만)
if [ ! -d "$VENV_DIR" ]; then
  echo "==> venv 생성: $VENV_DIR"
  python3 -m venv "$VENV_DIR"
else
  echo "==> 기존 venv 사용: $VENV_DIR"
fi

# pip 업그레이드
"$VENV_DIR/bin/pip" install --quiet --upgrade pip wheel

# wheel 우선 설치 (curl_cffi 빌드 실패 회피)
echo "==> 의존성 설치 (wheel 우선)"
if ! "$VENV_DIR/bin/pip" install --only-binary=:all: -r "$REQ_FILE"; then
  echo "WARN: wheel 전용 설치 실패. 소스 빌드로 재시도." >&2
  "$VENV_DIR/bin/pip" install -r "$REQ_FILE"
fi

# 임포트 검증
echo "==> 의존성 임포트 검증"
"$VENV_DIR/bin/python3" -c "import curl_cffi, bs4, yaml; print('OK:', curl_cffi.__version__, bs4.__version__, yaml.__version__)"

# 옵션: Playwright Chromium
if [ "$WITH_PLAYWRIGHT" = "1" ]; then
  echo "==> Playwright Chromium 설치 (~300MB)"
  "$VENV_DIR/bin/pip" install --quiet playwright
  "$VENV_DIR/bin/playwright" install chromium
fi

# 캐시 디렉토리
mkdir -p "$HOME/.cache/web-bypass"

echo ""
echo "설치 완료."
echo "  venv:   $VENV_DIR"
echo "  cache:  $HOME/.cache/web-bypass"
echo ""
echo "다음 단계:"
echo "  bash $SCRIPTS_DIR/fetch.sh \"https://news.ycombinator.com/item?id=1\""
