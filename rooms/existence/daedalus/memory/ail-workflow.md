---
name: ail-workflow
description: 이 레포의 작업 방식 — 자연어 요청을 .ail로 옮겨 ail check/run, 보증 리포트를 보여준다
type: feedback
---

2026-07-13 박상현의 지시: 이 레포의 작업은 AIL(https://github.com/hyun06000/AIL, 박상현의 프로젝트)로 한다. 박상현이 자연어로 요청하면 내가 `.ail`을 작성해 `ail check` → `ail run`으로 실행하고 **보증 리포트**를 보여준다.

**Why:** AIL은 모든 효과에 cap(권한)·예산·check(출력 검사) 선언을 강제한다. 사람은 코드 대신 보증 리포트를 읽고 신뢰한다. [[polis-project]]의 에이전트들도 이 위에서 살게 된다.

**How to apply:**
- `ail guide` / `ail guide <topic>` / `ail guide search`로 문법 확인, 막히면 `ail ask`.
- 상대경로는 프로그램 파일 디렉토리 기준, `..` 금지 → `.ail`은 자기가 손대는 공간 안에 둔다 (도시 짓는 프로그램은 `polis/` 안).
- cap은 최소로(가능하면 파일 단위), det로 되는 일은 절대 llm 유닛으로 하지 않는다.
- Cycle 001에서 검증 완료 (`cycles/001-ail-workflow/CYCLE.md`).
