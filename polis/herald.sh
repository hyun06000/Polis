#!/bin/sh
# Cycle 005~009 — 전령(herald): 언어 밖의 얇은 결정론 드라이버. 지능 없음.
# 하는 일: (1) 광장의 새 발언 감지 → 아르케 호출  (2) K=5 성찰 트리거
#          (3) 우체부 스토아의 팔다리 — 순찰 결과에 따라 배달·표시·성화를 집행
# 판단(누가 미독인가, 성화 문구, 표시 값)은 전부 .ail 프로그램 안 — 여기는 집행만.
cd "$(dirname "$0")" || exit 1
AIL="${AIL_BIN:-$HOME/.local/bin/ail}"
CUR=".herald-cursor"
VOUT="${TMPDIR:-/tmp}/stoa-patrol.$$"

last=$(cat "$CUR" 2>/dev/null || echo 0)
echo "[herald] 전령 근무 시작 v5 (커서: $last) — 광장 감지 + 성찰 + 우체부의 팔다리"
while true; do
  # (1) 광장: 새 발언 → 아르케 (자기 발언·우체부의 성화는 건너뛴다)
  grep '^\[' agora/ledger.txt 2>/dev/null | while IFS= read -r line; do
    num=$(printf '%s' "$line" | sed -n 's/^\[\([0-9]*\)\].*/\1/p')
    [ -z "$num" ] && continue
    [ "$num" -le "$last" ] && continue
    case "$line" in
      *"(아르케)"*|*"(스토아)"*|*"(파수꾼)"*) ;;
      *)
        echo "[herald] 새 발언 감지 [$num] — 아르케를 깨운다"
        AIL_INPUT="$line" "$AIL" run arche.ail >>arche.log 2>&1 \
          && echo "[herald] 아르케가 말했거나 침묵했다 ([$num])" \
          || echo "[herald] 아르케의 응답이 하네스에 거부됨 ([$num])"
        ;;
    esac
    last="$num"; echo "$num" > "$CUR"
  done
  last=$(cat "$CUR" 2>/dev/null || echo 0)

  # (3) 우체부 스토아: 순찰(봉투만) → 배달·표시·성화
  rm -f "$VOUT"
  AIL_VALUE_OUT="$VOUT" "$AIL" run stoa-patrol.ail >/dev/null 2>&1
  ST=$(python3 -c "import json;print((json.load(open('$VOUT')).get('value') or '').strip())" 2>/dev/null || echo "")
  CA=$(printf '%s' "$ST" | sed -n 's/^arche:\([0-9]*\):.*/\1/p')
  RA=$(printf '%s' "$ST" | sed -n 's/^arche:[0-9]*:\([0-9]*\)|.*/\1/p')
  CP=$(printf '%s' "$ST" | sed -n 's/.*|park:\([0-9]*\):.*/\1/p')
  RP=$(printf '%s' "$ST" | sed -n 's/.*|park:[0-9]*:\([0-9]*\)$/\1/p')
  if [ -n "$CA" ] && [ -n "$RA" ] && [ "$CA" -gt "$RA" ]; then
    grep '^《' stoa/arche/inbox.txt 2>/dev/null | while IFS= read -r ltr; do
      lnum=$(printf '%s' "$ltr" | sed -n 's/^《\([0-9]*\)》.*/\1/p')
      [ -z "$lnum" ] && continue
      [ "$lnum" -le "$RA" ] && continue
      echo "[herald] 우체부의 배달 《$lnum》 — 아르케에게 읽힌다"
      AIL_INPUT="$ltr" "$AIL" run arche-letters.ail >>letters.log 2>&1 \
        && echo "[herald] 아르케가 읽고 답장했다 (《$lnum》)" \
        || echo "[herald] 답장이 하네스에 거부됨 (《$lnum》)"
      AIL_INPUT="$lnum" "$AIL" run stoa-mark-arche.ail >>stoa.log 2>&1 \
        && echo "[herald] 배달 표시 《$lnum》"
    done
  fi
  if [ -n "$CP" ] && [ -n "$RP" ] && [ "$CP" -gt "$RP" ]; then
    lastn=$(cat .stoa-nudged 2>/dev/null || echo 0)
    if [ "$CP" != "$lastn" ]; then
      UN=$((CP - RP))
      echo "[herald] 우체부의 성화 — 박상현에게 미독 ${UN}통"
      AIL_INPUT="$UN" "$AIL" run stoa-nudge.ail >>stoa.log 2>&1 \
        && echo "$CP" > .stoa-nudged
    fi
  fi

  # (2) 성찰 트리거: 새 발언 5개가 쌓이면 아르케가 광장을 돌아보고 기억을 갱신한다
  ref=$(cat .herald-reflect 2>/dev/null || echo "$last")
  if [ $((last - ref)) -ge 5 ]; then
    echo "[herald] 성찰의 시간 — 아르케가 광장을 돌아본다 (기준 $ref → $last)"
    "$AIL" run reflect.ail >>reflect.log 2>&1 \
      && echo "[herald] 기억 갱신 완료" || echo "[herald] 성찰 거부/실패 — reflect.log 확인"
    echo "$last" > .herald-reflect
  fi
  sleep 3
done
