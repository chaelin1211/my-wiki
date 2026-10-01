---
type: decision-record
project: dna-sql-agent
date: 2026-08-20
status: accepted
superseded-by: ""
tags: [llm-tool, chart, api-design]
---

# ADR-038: 차트 형태는 타입으로 정하고 인자로 바꾸지 않는다

## 맥락

수량과 비율처럼 스케일이 다른 지표를 한 차트에 그리려면 이중 축이 필요하다. echarts 에는 `combo` 타입이 있었지만 plotly 에는 없었고, plotly 를 쓰는 동안 LLM 이 `combo` 를 요청해 도구 호출이 반복 실패했다.

이중 축을 어떤 인터페이스로 노출할지 정해야 했다. 새 타입을 만들면 [[decisions/037-engine-capability-gating-in-tool-schema|엔진별 타입 목록이 갈리는 문제]]가 커지므로, 모든 엔진이 가진 `bar` 에 얹는 방안이 먼저 검토됐다.

## 선택지

### 옵션 A: `bar` + `value` 로 이중 축
- **장점:** `bar` 는 세 엔진 모두 지원하므로 타입 목록이 갈리지 않는다. 다중 y 를 `bar` 에 얹은 것과 같은 결.
- **단점:** 같은 `bar` 인데 인자 유무로 결과가 달라진다. 결과 문구는 `Created bar chart` 인데 실제로는 이중 축이라, LLM 이 "이중 축은 지원되지 않는다"고 사용자에게 답했다.
- **비용/노력:** 작음.

### 옵션 B: `combo` 를 각 엔진에 정식 타입으로 추가
- **장점:** 요청과 결과가 이름으로 일치한다. `bar` 는 항상 막대만 그린다.
- **단점:** 엔진마다 구현·노출 여부를 관리해야 한다.
- **비용/노력:** 중간. plotly 는 백엔드만, devextreme 은 프론트 렌더러 선행.

## 결정

**옵션 B 를 선택한다.** 이중 축은 `combo` 타입으로만 그린다. `bar` 는 `value` 가 와도 무시하고 막대만 그린다.

- `y` — 주 y축 막대 (쉼표로 여러 개)
- `value` — 보조 y축 선 (쉼표로 여러 개)

plotly 에 `combo` 를 구현해 echarts 와 같은 이름·같은 인자로 맞췄다. devextreme 은 프론트엔드가 축을 2개 받지 못해 미구현으로 두고, 목록에 넣지 않아 노출되지 않는다.

## 근거

옵션 A 를 구현했다가 되돌렸다. 인자로 형태가 바뀌면 **결과를 이름으로 설명할 수 없다.** 도구가 "bar 를 그렸다"고 보고하는데 화면에는 이중 축이 있으면, LLM 은 자기 요청이 반영되지 않았다고 판단한다. 실제로 그렇게 답했다.

보조축 계열을 막대로 그리는 변형(막대 3개 중 하나만 우측 눈금)도 함께 검토했으나 폐기했다. `combo`(막대+선)와 형태가 겹치면서 인자 조합만 다른 또 하나의 암묵 규칙이 되기 때문이다.

`color` 를 보조축 컬럼으로 재활용하는 초안(웹 `dual-axis-chart-design.md`)도 같은 이유로 채택하지 않았다. `color` 는 long-format 그룹핑 전용이고, 타입에 따라 뜻이 달라지면 LLM 이 매번 판단해야 한다.

## 결과

- 세 엔진이 같은 이름·같은 인자(`y`/`value`)를 쓴다. devextreme 이 붙어도 타입 이름은 그대로다.
- 이중 축 자동 판정(스케일 비율 100배 초과 시 자동 전환)은 두지 않는다. 단위가 같고 규모만 다른 경우를 오판하고, 요청하지 않은 축을 시스템이 만들면 결과를 설명할 근거가 사라진다.
- 대신 도구 설명에 선택 기준을 적어 유도한다 — 단위·스케일이 같으면 `y` 에 쉼표로 묶고, 다르면 `combo`.
- 웹 문서를 `docs/combo-chart-design.md` 로 이름 바꿔 정본화했다.

## 참고 자료

- PR: DnA-Platform-Development-Team/dna-sql-agent#154
- 웹 문서: `dna-sql-agent-web` `docs/combo-chart-design.md`
- [[decisions/037-engine-capability-gating-in-tool-schema]]
