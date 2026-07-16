#!/bin/sh
# Cycle 004 → gil C001 — 파수꾼(warden) v2: 도시 전체의 수호자. 지능 없는 드라이버.
# 기관 명단 전체를 기르고, 죽음을 감지하면 검시(광장=전용, 그 외=범용)를 부른 뒤
# 부활시키고, 부활 공지를 광장의 정문(POST)으로 발언한다.
# 파수꾼 자신의 죽음은 범위 밖 (gil C001 설계에 명시).
cd "$(dirname "$0")" || exit 1
LOGDIR="."
AIL="${AIL_BIN:-$HOME/.local/bin/ail}"
DRIVER="$HOME/.ail/drivers/serve.py"
AGORA_PORT=8766

# 기관 명단 — 이름:핸들러:포트
ORGANS="viewer:viewer.ail:8765
agora:agora.ail:8766
postbox-arche:stoa/arche/postbox.ail:8767
postbox-park:stoa/park/postbox.ail:8768"

start_organ() { # $1=name $2=handler $3=port
  python3 "$DRIVER" "$2" --port "$3" >>"$LOGDIR/$1-server.log" 2>&1 &
  eval "PID_$(printf '%s' "$1" | tr '-' '_')=$!"
  echo "[warden] $1 기동 (port $3)"
}

pid_of() { eval "printf '%s' \"\$PID_$(printf '%s' "$1" | tr '-' '_')\""; }

# 초기 기동: 이미 떠 있는 포트는 두고, 죽어 있는 기관만 세운다
IFS='
'
for line in $ORGANS; do
  n=${line%%:*}; rest=${line#*:}; h=${rest%%:*}; p=${rest##*:}
  if curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$p/"; then
    echo "[warden] $n 이미 근무 중 (port $p) — 입양 불가, 감시는 포트로 한다"
  else
    start_organ "$n" "$h" "$p"
  fi
done

while true; do
  sleep 3
  for line in $ORGANS; do
    n=${line%%:*}; rest=${line#*:}; h=${rest%%:*}; p=${rest##*:}
    if ! curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$p/"; then
      # 이중 확인 (일시적 부하 오탐 방지)
      sleep 1
      if ! curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$p/"; then
        TAIL=$(tail -c 150 "$LOGDIR/$n-server.log" 2>/dev/null | tr '\n' ' ')
        echo "[warden] $n 사망 감지 (port $p 무응답) — 검시관 소환"
        if [ "$n" = "agora" ]; then
          AIL_INPUT="exit=? log=$TAIL" "$AIL" run necropsy.ail >>necropsy.log 2>&1 \
            && echo "[warden] $n 전용 검시 완료 (유서+파라미터 유전)"
        else
          AIL_INPUT="organ=$n exit=? log=$TAIL" "$AIL" run necropsy-city.ail >>necropsy.log 2>&1 \
            && echo "[warden] $n 범용 검시 완료 (도시 유서)"
        fi
        start_organ "$n" "$h" "$p"
        sleep 1
        if [ "$n" = "agora" ]; then
          GEN=$(cat .ail-state/agora_gen 2>/dev/null || echo '?')
          curl -s -X POST --data "(파수꾼) 제${GEN}세대 아고라가 유서를 읽고 깨어났다." "http://127.0.0.1:$AGORA_PORT/" >/dev/null 2>&1 || true
        else
          curl -s -X POST --data "(파수꾼) 기관 $n 이(가) 죽었다가 부활했다. 유서는 도시 보관소에." "http://127.0.0.1:$AGORA_PORT/" >/dev/null 2>&1 || true
        fi
        echo "[warden] $n 부활"
      fi
    fi
  done
done
