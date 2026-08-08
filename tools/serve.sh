#!/bin/bash
# Відкриває апку для телефона: піднімає локальний сервер і показує адресу.
# Телефон і Mac мають бути в одному Wi-Fi.
# Зупинити — Ctrl+C.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${1:-8080}"

IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
[ -z "$IP" ] && IP="localhost"

echo ""
echo "  Відкрийте на телефоні:   http://$IP:$PORT"
echo "  На цьому Mac:            http://localhost:$PORT"
echo ""
echo "  (Ctrl+C щоб зупинити)"
echo ""

cd "$ROOT"
python3 -m http.server "$PORT" --bind 0.0.0.0
