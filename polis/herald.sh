#!/bin/sh
# Cycle 005~007 — 전령(herald): 언어 밖의 얇은 결정론 드라이버. 지능 없음.
# v3 (Cycle 007): 배달 다리 은퇴 — 아르케가 제 입(http.post)으로 말한다.
# 남는 일: 새 발언 감지(연번 커서, 회전 안전), 아르케 호출, K=5 성찰 트리거.
# (아르케) 자신의 발언은 기계적으로 건너뛴다 — 자기응답 루프 차단.
cd "$(dirname "$0")" || exit 1
AIL="${AIL_BIN:-$HOME/.local/bin/ail}"
CUR=".herald-cursor"

last=$(cat "$CUR" 2>/dev/null || echo 0)
echo "[herald] 전령 근무 시작 v3 (커서: $last) — 배달은 하지 않는다, 아르케가 직접 말한다"
while true; do
  grep '^\[' agora/ledger.txt 2>/dev/null | while IFS= read -r line; do
    num=$(printf '%s' "$line" | sed -n 's/^\[\([0-9]*\)\].*/\1/p')
    [ -z "$num" ] && continue
    [ "$num" -le "$last" ] && continue
    case "$line" in
      *"(아르케)"*) ;;  # 자기 발언은 듣기만 한다
      *)
        echo "[herald] 새 발언 감지 [$num] — 아르케를 깨운다"
        AIL_INPUT="$line" "$AIL" run arche.ail >>arche.log 2>&1 \
          && echo "[herald] 아르케가 말했거나 침묵했다 ([$num] — arche.log)" \
          || echo "[herald] 아르케의 응답이 하네스에 거부됨 ([$num] — arche.log)"
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
