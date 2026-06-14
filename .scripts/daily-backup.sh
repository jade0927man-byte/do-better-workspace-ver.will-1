#!/bin/bash
# 매일 자동 백업 스크립트 — do-better-workspace
cd "$(dirname "$0")/.."

# 변경사항 있을 때만 커밋
if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -m "backup: $(date '+%Y-%m-%d') 자동 백업"
  git push origin main
fi
