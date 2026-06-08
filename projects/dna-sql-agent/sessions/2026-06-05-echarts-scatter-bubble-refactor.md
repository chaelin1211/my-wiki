---
type: session-log
project: dna-sql-agent
date: 2026-06-05
duration: ~4h
focus: "ECharts scatter/bubble 개선 및 프론트·백 레이아웃 책임 분리"
tools-used: [claude-code]
outcome: success
---

# 2026-06-05 — ECharts scatter/bubble 개선 및 레이아웃 책임 분리

## 목표

- ECharts 산점도/버블 차트 버블 크기 미반영 버그 수정
- 툴팁 정상화
- 프론트/백 레이아웃 책임 명확히 분리

## 수행한 작업

1. **버블 크기 버그 수정** — `visualMap` 데이터가 문자열로 전달되어 크기 매핑 안 됨
   - `sub[size] = pd.to_numeric(...).dropna()` 로 float 보장
   - `max(s_max, s_min + 1)` 로 min==max 엣지케이스 처리
   - `type: "continuous"`, `seriesIndex: 0` 명시

2. **툴팁 정상화** — `{c0}`, `{c1}` item trigger 미동작 → `{b}` + `white-space: pre-line` 방식으로 전환
   - 데이터를 `{value: [...], name: "col: v\ncol2: v2"}` 객체 포맷으로 변경
   - HTML 태그가 텍스트로 출력되는 문제 → `\n` + CSS pre-line으로 해결

3. **프론트/백 레이아웃 책임 분리** — ADR-007
   - `COLOR_PALETTE` 프론트로 이전 (백에서 `color` 속성 전부 제거)
   - `tooltip.confine` 프론트 기본값으로 처리
   - `grid` 레이아웃(top/bottom/containLabel) 프론트 전담
   - `echarts-chart-block.tsx`에 `resolvedOption` 머지 로직 통합

4. **cartesian tooltip axisPointer** — bar계열 `shadow`, line계열 `line` 자동 분기

5. **버블 border 색** — `rgba(0,0,0,0.3)` → `rgba(255,255,255,0.8)` (흰색)

6. **Sankey DAG 사이클 오류** — `_remove_sankey_cycles()` iterative DFS 구현
   - self-loop 제거 + back-edge 감지 및 제거
   - 실제 원형 데이터(A→B→A)에서 오류 없이 주요 흐름 유지

7. **DevExtreme bubble 지원** — `scatter + size` 파라미터 → `type: "bubble"` 자동 변환

8. **코드 리뷰 후 버그 수정**
   - `_label` 함수 `float('inf')` OverflowError → try/except 처리
   - DX bubble x축 numeric 강제 (`bx = x if x in numeric_cols else numeric_cols[0]`)

9. **문서화** — `docs/echarts-chart-design.md` 섹션 11 추가

## 핵심 결정

- **ECharts 레이아웃은 프론트가 소유한다**: 백은 데이터 인코딩만, 프론트가 grid/height/color/confine 전담
  → ADR: [[decisions/007-echarts-layout-frontend-ownership]]

- **ECharts tooltip은 JSON 기반에서 `{b}` + pre-line이 가장 신뢰성 높은 방식**
  → knowledge: [[knowledge/tools/echarts-tooltip-json-patterns]]

- **Sankey 사이클은 데이터 문제이지만 차트 레이어에서 방어적으로 제거**

## 배운 것

- ECharts `{c0}`, `{c1}` — axis trigger 다중 시리즈 전용. item trigger 단일 시리즈에서 미동작
- ECharts `{b}` placeholder — HTML escape 처리됨. 함수 formatter 없이 HTML 렌더 불가
- `np.float64` 는 Python `float` 의 subclass → `isinstance` 체크 가능
- ECharts visualMap `dimension` — `value[N]` 배열 인덱스 기준으로 symbolSize 매핑
- Sankey DAG 오류: 동일 노드명이 여러 tier에 걸쳐 역방향 링크 생성 시 발생

## 문제 & 해결

- **문제:** 버블 크기가 모두 동일하게 렌더됨
- **원인:** `visualMap`에 전달되는 data 배열의 dimension 2 값이 문자열 타입
- **해결:** `pd.to_numeric` + `dropna` 후 float 보장
  → 이슈: [[issues/echarts-bubble-size-not-changing]]

- **문제:** Sankey "DAG has cycle" ECharts 오류
- **원인:** 원본 데이터에 A→B→A 형태 역방향 흐름 존재
- **해결:** `_remove_sankey_cycles()` iterative DFS로 back-edge 제거
  → 이슈: [[issues/echarts-sankey-dag-cycle]]

- **문제:** 툴팁에 `<b>`, `<br>` 태그가 텍스트로 출력
- **원인:** ECharts `{b}` placeholder가 name 값을 HTML escape 처리
- **해결:** `\n` + `extraCssText: "white-space: pre-line"` 조합

## 다음 할 일

- [ ] 7번 오판 케이스 수정 — `CALENDAR_YEAR` 같은 연도 정수가 scatter 대신 bar/line 선택되도록
- [ ] SH/HR/OE 스키마 기반 심화 테스트 12개 시나리오 실행
- [ ] PR #39 머지 후 ECharts 브랜치 정리
