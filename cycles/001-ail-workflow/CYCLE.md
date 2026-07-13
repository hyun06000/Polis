# Cycle 001 — AIL 워크플로 검증

- **기간**: 2026-07-13 ~ 2026-07-13
- **상태**: 완료
- **참여**: 박상현, 다이달로스

## 1. 이전 사이클로부터의 교훈

없음 (첫 사이클). 시작 배경: 박상현이 이 레포의 작업 방식을 정했다 — 자연어 요청을 다이달로스가 `.ail` 프로그램으로 옮기고, `ail check`와 `ail run`으로 실행하며, 사람은 코드 대신 **보증 리포트**를 읽는다. AIL은 모든 효과(파일·네트워크·상태)에 권한(cap)·예산·출력 검사(check) 선언을 강제하는 언어다 (https://github.com/hyun06000/AIL).

## 2. 가설

> 자연어 요청을 다이달로스가 `.ail`로 옮겨 `ail check` → `ail run`으로 실행하면, 사람은 코드를 읽지 않고 보증 리포트만으로 무엇이 허용되었고 무엇이 실행되었는지 신뢰할 수 있다.

## 3. 실험 설계

- 첫 자연어 요청: "폴리스의 주춧돌을 놓아라" — 창건 선언문을 `polis/foundation.txt`에 기록.
- `foundation.ail`을 작성한다. 효과는 `fs.write` 하나, cap은 `polis/` 디렉토리로 최소화, 선언문에는 길이·내용 check를 건다.
- 관찰할 것: (a) `ail check`가 VALID에 도달하는가, (b) `ail run`이 파일을 만들고 보증 리포트를 출력하는가, (c) 리포트가 cap/check/실행 내용을 사람이 읽을 수 있게 보여주는가.
- (a)(b)(c) 모두 확인되면 가설 검증. 하나라도 안 되면 원인을 기록하고 기각/보류 판정.

## 4. 실험 기록

- `ail` 0.8.0을 원격 설치 스크립트로 설치 (`~/.local/bin/ail`, 소스 `~/.ail-src`). `ail guide`(core/ops/caps/checks)로 문법 학습.
- `foundation.ail` 작성: det 유닛 5개(const×3, concat, fs.write), cap 1개, check 2개(minchars/contains), LLM 호출 0회.
- 첫 `ail check`에서 바로 VALID. `ail run`도 성공.
- **예상과 달랐던 지점**: 처음엔 프로그램을 `cycles/001-ail-workflow/`에 두고 레포 루트에서 실행했는데, 파일이 레포 루트의 `polis/`가 아니라 `cycles/001-ail-workflow/polis/`에 생겼다. AIL의 상대경로는 실행 위치(CWD)가 아니라 **프로그램 파일의 디렉토리 기준**이고, `..`과 절대경로는 금지라 프로그램은 자기 디렉토리 밖을 쓸 수 없다.
- 이에 따라 프로그램을 `polis/foundation.ail`로 옮기고 cap을 디렉토리(`polis/`)에서 파일 단위(`foundation.txt`)로 좁혀 재실행 → 성공. 보증 리포트 전문은 아래.

```
=== AIL 보증 리포트 ===
목표: 폴리스의 창건 선언문을 foundation.txt에 기록한다
선언된 권한:
  c1 fs.write foundation.txt — 1회 사용
LLM 호출:
  (없음)
프로바이더 총사용: 0tok
정적 최대 소비 상한: 0tok (프로그램 총예산 미선언 — 이 상한이 유일한 천장)
검증:
  k1 on decl [det.minchars] — 통과
  k2 on decl [det.contains] — 통과
수행된 효과:
  fs.write foundation.txt (78 chars) via c1
결과 방출(emit): 성공
결과값: written:foundation.txt
```

## 5. 결과

**가설 검증됨.** (a) `ail check` VALID 도달, (b) `ail run`이 `polis/foundation.txt`를 생성, (c) 보증 리포트가 선언된 권한·검증 결과·수행된 효과·토큰 비용을 사람이 읽을 수 있는 형태로 보여줌. 코드를 읽지 않아도 "foundation.txt 하나에만 쓸 수 있었고, 두 검사를 통과했고, 모델 호출 없이 78자를 썼다"를 리포트만으로 알 수 있다.

## 6. 교훈

1. **AIL 프로그램은 자기가 손대는 공간 안에 살아야 한다.** 상대경로는 프로그램 파일 기준이고 `..`은 금지다. → 규약: 도시를 짓는 `.ail`은 `polis/` 안에 둔다. 도시는 도시 안에서 짓는다.
2. **cap은 처음부터 최소로.** 디렉토리 cap(`polis/`)으로 시작했다가 파일 cap(`foundation.txt`)으로 좁혔다. 보증 리포트의 신뢰도는 cap의 좁기에서 나온다.
3. **det로 되는 일은 det로.** 이번 프로그램은 LLM 호출 0회, 0tok. 보증 리포트의 "프로바이더 총사용: 0tok" 한 줄이 그 자체로 강력한 보증이다.
4. 다음 사이클 후보: llm 유닛·state·핸들러(에이전트)를 실험해 폴리스의 첫 주민을 AIL로 입주시키기.
