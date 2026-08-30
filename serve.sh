#!/bin/bash
# ============================================================
# Only Money - 로컬 서버 실행 (macOS / Linux)
# Terminal에서 ./serve.sh 또는 더블클릭으로 실행
# ============================================================

cd "$(dirname "$0")"
echo ""
echo " =================================================="
echo "  Only Money - Local Server"
echo " =================================================="
echo ""
echo "  Starting server at http://localhost:8000 ..."
echo "  Press Ctrl+C to stop."
echo ""

# 브라우저 자동 오픈
if command -v open >/dev/null 2>&1; then
  open "http://localhost:8000" &
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "http://localhost:8000" &
fi

# Python 우선
if command -v python3 >/dev/null 2>&1; then
  exec python3 -m http.server 8000
elif command -v python >/dev/null 2>&1; then
  exec python -m http.server 8000
elif command -v npx >/dev/null 2>&1; then
  exec npx --yes serve -p 8000
else
  echo "  [!] Python 또는 Node.js 필요"
  echo "      brew install python  (또는 https://python.org)"
  read -p "Enter to exit..."
fi
