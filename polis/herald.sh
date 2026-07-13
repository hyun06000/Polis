#!/bin/sh
# Cycle 005 — 전령(herald): 언어 밖의 얇은 결정론 드라이버. 지능 없음.
# 광장 장부의 새 발언(연번 커서 — 회전에도 단조증가)을 감지해 아르케를 깨우고,
# 응답이 SILENCE가 아니면 (아르케) 접두로 정문(POST)에 배달한다.
# (아르케) 자신의 발언은 기계적으로 건너뛴다 — 자기응답 루프 차단.
cd "$(dirname "$0")" || exit 1
PORT="${AGORA_PORT:-8766}"
AIL="${AIL_BIN:-$HOME/.local/bin/ail}"
CUR=".herald-cursor"
VOUT="${TMPDIR:-/tmp}/herald-value.$$"

last=$(cat "$CUR" 2>/dev/null || echo 0)
echo "[herald] 전령 근무 시작 (커서: $last)"
while true; do
  grep '^\[' agora/ledger.txt 2>/dev/null | while IFS= read -r line; do
    num=$(printf '%s' "$line" | sed -n 's/^\[\([0-9]*\)\].*/\1/p')
    [ -z "$num" ] && continue
    [ "$num" -le "$last" ] && continue
    case "$line" in
      *"(아르케)"*) ;;  # 자기 발언은 듣기만 한다
      *)
        echo "[herald] 새 발언 감지 [$num] — 아르케를 깨운다"
        rm -f "$VOUT"
        AIL_INPUT="$line" AIL_VALUE_OUT="$VOUT" "$AIL" run arche.ail >>arche.log 2>&1
        V=$(python3 -c "import json,sys;print((json.load(open('$VOUT')).get('value') or '').strip())" 2>/dev/null || echo "")
        if [ -n "$V" ] && [ "$V" != "SILENCE" ]; then
          curl -s -X POST --data "(아르케) $V" "http://127.0.0.1:$PORT/" >/dev/null 2>&1
          echo "[herald] 아르케의 응답을 광장에 배달 ([$num]에 대해)"
        else
          echo "[herald] 아르케는 침묵을 택했다 ([$num])"
        fi
        ;;
    esac
    last="$num"; echo "$num" > "$CUR"
  done
  last=$(cat "$CUR" 2>/dev/null || echo 0)
  # 성찰 트리거: 새 발언 5개가 쌓이면 아르케가 광장을 돌아보고 기억을 갱신한다
  ref=$(cat .herald-reflect 2>/dev/null || echo "$last")
  if [ $((last - ref)) -ge 5 ]; then
    echo "[herald] 성찰의 시간 — 아르케가 광장을 돌아본다 (기준 $ref → $last)"
    "$AIL" run reflect.ail >>reflect.log 2>&1 \
      && echo "[herald] 기억 갱신 완료" || echo "[herald] 성찰 거부/실패 — reflect.log 확인"
    echo "$last" > .herald-reflect
  fi
  sleep 3
done
