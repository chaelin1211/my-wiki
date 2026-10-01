---
type: decision-record
project: dna-sql-agent
date: 2026-08-20
status: accepted
superseded-by: ""
tags: [llm-tool, chart, schema]
---

# ADR-037: 엔진별 차트 능력 차이를 도구 스키마에서 흡수한다

## 맥락

시각화 도구는 차트 엔진 셋(plotly · devextreme · echarts)을 설정으로 전환한다. 엔진마다 그릴 수 있는 차트가 다르다 — `sankey`·`combo` 는 echarts 에만, `stackedBar` 계열은 devextreme·echarts 에만 있다.

`chart_type` 은 엔진별 `Literal` 로 좁혀져 있었지만 파라미터 설명(`x`/`y`/`value`/`color`)은 정적이었다. 그래서 현재 엔진에 없는 타입이 `value` 설명 등을 통해 LLM 에게 노출됐고, 모델이 그 타입을 요청하면 `Invalid arguments` 로 도구 호출이 통째로 실패했다. 실패 메시지가 pydantic 원본이라 고치기 어려워 같은 호출을 3번까지 반복했다.

## 선택지

### 옵션 A: 모든 엔진이 모든 타입을 지원하게 만든다
- **장점:** 분기가 사라진다. 설명 하나로 끝난다.
- **단점:** 렌더러 제약을 무시할 수 없다 — devextreme 이중 축은 프론트엔드가 축을 2개 받아야 하고, plotly 에는 sankey 가 없다. 엔진을 추가할 때마다 전 타입을 구현해야 한다.
- **비용/노력:** 큼. 웹 저장소까지 걸친다.

### 옵션 B: 지원 밖 타입이 오면 근사 타입으로 대체해 그린다
- **장점:** 도구가 실패하지 않는다. 사용자는 항상 차트를 받는다.
- **단점:** 실제로 해보니 LLM 이 대체 안내 문구를 실패로 읽고 재생성해, 사용자 화면에 같은 시각화가 3개 떴다. 요청한 지표가 조용히 빠지기도 한다.
- **비용/노력:** 작음.

### 옵션 C: 지원 목록으로 스키마를 조립하고, 그럼에도 오면 사유를 담아 실패시킨다
- **장점:** 애초에 요청되지 않는다. 요청되더라도 LLM 이 한 턴에 고칠 수 있는 오류를 받는다. 무엇으로 대신 그릴지는 의도를 아는 LLM 이 정한다.
- **단점:** 강제는 아니다. 모델이 어기면 한 턴을 소비한다.
- **비용/노력:** 중간. 설명 조립 구조가 필요하다.

### 옵션 D: provider 의 strict function calling 으로 제약 디코딩
- **장점:** 모델이 `enum` 밖 값을 생성조차 못 한다. 진짜 강제.
- **단점:** 전 프로퍼티 `required`·`additionalProperties: false` 등 스키마 제약이 크다. `src/vanna` 공용 LLM 어댑터를 바꿔야 해 전 도구가 영향받고, provider 별 지원도 갈린다(Ollama 사실상 없음).
- **비용/노력:** 큼.

## 결정

**옵션 C 를 선택한다.** 옵션 D 는 별도 과제로 남긴다.

세 층으로 나눈다.

1. **비노출** — `CHART_TYPES_BY_ENGINE` 이 엔진별 목록을 정하고, 도구 설명 상단에 그 목록을 싣는다. 차트 타입별 축 용법은 `CHART_TYPE_AXIS_HINTS` 에 데이터로 두고 현재 엔진 목록으로 걸러 `x`/`y`/`value`/`color` 설명을 조립한다.
2. **검증 통과** — `chart_type` 을 `Literal` 에서 `str` + `json_schema_extra={"enum": types}` 로 바꾼다. `enum` 은 유도용으로 남기되 pydantic 이 튕기지 않게 한다.
3. **사유 있는 실패** — `execute()` 에서 지원 밖 타입이면 엔진 이름과 사용 가능한 타입 전체를 담은 오류를 반환한다. 차트는 만들지 않는다.

## 근거

옵션 B 를 실제로 구현해 보고 되돌렸다. 도구가 대신 판단하면 LLM 이 그 결과를 신뢰하지 못하고 재시도하며, 그 부작용이 사용자 화면(중복 차트)에 그대로 드러난다. 무엇으로 대체할지는 데이터와 질문 의도를 함께 아는 LLM 이 정하는 편이 낫다.

`Literal` 을 걷은 것은 방어를 포기한 게 아니라 **오류의 질**을 바꾼 것이다. pydantic 원본 오류는 정보가 없어 맹목적 재시도를 부르고, 우리가 만든 오류는 엔진 이름과 선택지를 한 문장에 담아 한 턴에 복구된다.

## 결과

- 엔진에 타입을 추가하면 `CHART_TYPES_BY_ENGINE` 한 줄로 설명·스키마가 함께 따라온다.
- 미지원 타입이 어느 설명에도 새지 않는지 전 엔진 교차 검사로 고정했다. 이 과정에서 `color` 설명의 타입 나열과 `sankey` 언급도 새고 있던 것을 발견해 함께 정리했다.
- 완전 강제는 아니다. 모델이 어기면 한 턴을 쓴다. 재발이 잦으면 옵션 D 를 재검토한다.
- 관련: [[decisions/038-chart-shape-by-type-not-by-argument]]

## 참고 자료

- PR: DnA-Platform-Development-Team/dna-sql-agent#154
- [[issues/llm-denies-capability-missing-from-tool-schema]]
- [[knowledge/patterns/llm-tool-schema-mirrors-implementation]]
