#!/usr/bin/env bash
# 업스트림 fivetaku/insane-search 동기화
#
# vendored 영역(engine/, references/, LICENSE)만 갱신.
# scripts/, SKILL.md, README.md, NOTICE는 우리 자산이라 보존.
# CLI 시그니처가 바뀌면 fetch.py wrapper가 깨질 수 있으니 --help diff로 감지.

set -euo pipefail

SKILL=/Users/minchi/do-better-workspace/.claude/skills/web-bypass
HELP_OLD="$SKILL/.engine-help.txt"
HELP_NEW=$(mktemp)

if [ ! -d "$SKILL" ]; then
  echo "ERROR: $SKILL 미존재. 먼저 install 필요." >&2
  exit 1
fi

TMP=$(mktemp -d)
trap "rm -rf '$TMP' '$HELP_NEW'" EXIT

echo "==> upstream clone"
git clone --depth 1 https://github.com/fivetaku/insane-search "$TMP" 2>&1 | tail -3

NEW_SHA=$(cd "$TMP" && git rev-parse HEAD)
NEW_VER=$(grep '"version"' "$TMP/.claude-plugin/plugin.json" | head -1 | sed 's/.*"\([0-9.]*\)".*/\1/')

echo "==> rsync engine/ + references/ + LICENSE"
rsync -a --delete "$TMP/skills/insane-search/engine/" "$SKILL/engine/"
rsync -a --delete "$TMP/skills/insane-search/references/" "$SKILL/references/"
cp "$TMP/LICENSE" "$SKILL/LICENSE"

echo "fivetaku/insane-search@${NEW_SHA} v${NEW_VER} $(date +%Y-%m-%d) (renamed: web-bypass)" > "$SKILL/upstream.txt"

# CLI 시그니처 변경 감지 (fetch.py wrapper 영향)
if [ -x "$SKILL/scripts/venv/bin/python3" ]; then
  ( cd "$SKILL" && "$SKILL/scripts/venv/bin/python3" -m engine --help ) > "$HELP_NEW" 2>&1 || true
  if [ -f "$HELP_OLD" ]; then
    if ! diff -q "$HELP_OLD" "$HELP_NEW" > /dev/null 2>&1; then
      echo ""
      echo "WARN: engine CLI signature 변경 감지. fetch.py wrapper 검토 필요."
      echo "diff:"
      diff "$HELP_OLD" "$HELP_NEW" || true
    else
      echo "==> engine CLI signature 변화 없음"
    fi
  else
    echo "==> 첫 sync, baseline 저장"
  fi
  cp "$HELP_NEW" "$HELP_OLD"
else
  echo "INFO: venv 미설치, CLI signature 검사 생략"
fi

echo ""
echo "Sync 완료. upstream.txt:"
cat "$SKILL/upstream.txt"
