#!/bin/sh
# Cycle 004 — 파수꾼(warden): 언어 밖의 얇은 결정론 드라이버. 지능 없음.
# 아고라 서버를 기르고, 죽음을 감지하면 검시관(necropsy.ail)을 부른 뒤 부활시키고,
# 부활 인사를 정문(POST)으로 발언한다 — 부활의 역사도 check를 거쳐 장부에 남는다.
cd "$(dirname "$0")" || exit 1
PORT="${AGORA_PORT:-8766}"
LOG="${AGORA_LOG:-agora-server.log}"
AIL="${AIL_BIN:-$HOME/.local/bin/ail}"
DRIVER="$HOME/.ail/drivers/serve.py"

start() {
  python3 "$DRIVER" agora.ail --port "$PORT" >>"$LOG" 2>&1 &
  PID=$!
  echo "[warden] 아고라 기동 pid=$PID (port $PORT)"
}

start
while true; do
  sleep 2
  if ! kill -0 "$PID" 2>/dev/null; then
    wait "$PID" 2>/dev/null; CODE=$?
    TAIL=$(tail -c 200 "$LOG" 2>/dev/null | tr '\n' ' ')
    echo "[warden] 사망 감지 (exit=$CODE) — 검시관 소환"
    AIL_INPUT="exit=$CODE log=$TAIL" "$AIL" run necropsy.ail >>necropsy.log 2>&1 \
      && echo "[warden] 검시 완료" || echo "[warden] 검시 거부/실패 — necropsy.log 확인"
    start
    sleep 1
    GEN=$(cat .ail-state/agora_gen 2>/dev/null || echo '?')
    curl -s -X POST --data "(파수꾼) 제${GEN}세대 아고라가 유서를 읽고 깨어났다." "http://127.0.0.1:$PORT/" >/dev/null 2>&1 || true
    echo "[warden] 제${GEN}세대 부활"
  fi
done
