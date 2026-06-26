---
type: decision-record
project: dna-sql-agent
date: 2026-06-08
status: accepted
superseded-by: ""
tags: [echarts, sankey, visualization]
---

# ADR-008: Sankey 차트 컬럼 순서 기반 흐름 방향 아키텍처

## 맥락

ECharts Sankey 차트를 구현할 때, 다중 티어(3개 이상)의 흐름을 표현해야 했다.
기존 `x`, `y` 파라미터 기반 방식은 source/target 2-tier만 표현 가능했고,
LLM이 COUNTRY_ID 같은 ID 컬럼을 티어 컬럼으로 사용하거나 UNION ALL 타입 불일치(ORA-01790) 오류를 발생시키는 문제가 있었다.

핵심 질문: 멀티티어 Sankey의 흐름 방향을 어떻게 지정할 것인가?

## 선택지

### 옵션 A: 명시적 tier 파라미터 추가
- **장점:** API가 명확, LLM이 tier를 명시적으로 지정
- **단점:** tool schema 변경 필요, 가변 개수 tier를 파라미터로 표현하기 어려움
- **비용/노력:** 높음 (schema 변경, LLM 재학습 필요)

### 옵션 B: SELECT 컬럼 순서 = 흐름 방향 (자동 감지)
- **장점:** 추가 파라미터 없음, LLM이 SELECT 순서만 맞추면 됨, 3+ 티어 자연스럽게 지원
- **단점:** 암묵적 규약, 문서화 필수
- **비용/노력:** 낮음 (system prompt 규칙 2줄 추가)

### 옵션 C: x/y를 tier1/tier2로 재정의, value 뒤에 추가 tier를 콤마 구분
- **장점:** 기존 파라미터 활용
- **단점:** value 파라미터 의미 오염, LLM이 구분자 파싱 실수 가능
- **비용/노력:** 중간

## 결정

**옵션 B를 선택한다 — SELECT 컬럼 순서가 left→right 흐름 방향을 결정한다.**

## 근거

- LLM은 SELECT 컬럼 순서를 자연스럽게 제어할 수 있다.
- 3+ 티어를 `GROUP BY tier1, tier2, tier3, SUM(val)`으로 표현하면 추가 파라미터 없이 N-tier 지원.
- system prompt에 2줄 규칙을 추가하는 것으로 충분히 LLM에게 전달 가능.
- x/y 파라미터는 sankey에서 "사용하지 않음"으로 명시적으로 문서화.

## 결과

- `_build_sankey`에서 x, y 파라미터 무시, `df.columns`의 순서가 tier 순서
- `_compute_node_depths`: Kahn's topological sort로 left→right depth 계산
- `dna_visualize_data.py`: x, y 설명에 "sankey: 사용하지 않음" 명시
- system prompt 규칙:
  - "Sankey: SELECT column order = flow direction (left→right). Tier columns must be label columns (never ID/_CD/_KEY/_NO)."
  - "Sankey 3+ tiers: GROUP BY listing tier columns in flow order. UNION ALL is 2-tier only; cast with TO_CHAR() (ORA-01790)."
- 알려진 트레이드오프: 암묵적 규약이므로 LLM이 규칙을 망각하면 오류. system prompt 유지 필수.
- 향후 재검토: LLM이 반복적으로 규칙을 어기면 명시적 파라미터(옵션 A) 재검토.

## 참고 자료

- [[issues/echarts-sankey-oracle-decimal-tier-detection]]
- [[sessions/2026-06-08-echarts-chart-visualization-refactor]]
