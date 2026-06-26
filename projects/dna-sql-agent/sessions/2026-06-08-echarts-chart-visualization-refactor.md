---
type: session-log
project: dna-sql-agent
date: 2026-06-08
duration: 장시간 (컨텍스트 초과로 2회 분할)
focus: "ECharts combo/scatter label 추가, Sankey 버그 수정, 시스템 프롬프트 개선"
tools-used: [claude-code]
outcome: success
---

# 2026-06-08 — ECharts 차트 시각화 리팩토링

## 목표

- ECharts에 combo 차트(bar+line 이중 y축) 추가
- ECharts scatter에 `label` 파라미터 추가 (카테고리 값 per-item 표시)
- Sankey Oracle Decimal 티어 컬럼 오감지 버그 수정
- Sankey BFS 중복 큐 이슈 → Kahn's topological sort 교체
- 시스템 프롬프트 압축 및 섹션 헤더 영어 통일
- PR #45 생성

## 수행한 작업

1. **ECharts scatter `label` 파라미터 추가**
   - `DnaVisualizeDataTool`에 `label` 필드 추가 (scatter 전용)
   - `_build_scatter(df, x, y, size=None, label=None)` — per-item `data[i]["label"] = {"formatter": str(val)}` 방식
   - 카테고리 산점도에서 각 점에 텍스트 라벨 표시 가능

2. **ECharts combo 차트 추가**
   - `CHART_TYPES_BY_ENGINE["echarts"]`에 `"combo"` 추가
   - `_build_combo(df, x, y, value)` — `yAxis` 배열(이중 축), bar series(`yAxisIndex=0`), line series(`yAxisIndex=1`, smooth)
   - `axisPointer: {type: "cross"}` 크로스헤어 툴팁
   - 파라미터: `x`(카테고리), `y`(bar series 컬럼), `value`(line series 컬럼, 2차 y축)

3. **Sankey Oracle Decimal 티어 컬럼 오감지 수정**
   - `_normalize_df`에 `coerce_numeric=True` 기본값, sankey 시 `False` 전달
   - `_resolve_chart_type`을 `_normalize_df` **이전에** 호출하도록 순서 변경
   - Oracle 연도 코드('2023', '2024')가 int로 변환되어 categorical_cols 탈락하는 문제 해결

4. **Sankey BFS → Kahn's topological sort 교체**
   - 이전 BFS: neighbor가 큐에 중복 삽입되어 depth가 과도하게 증가
   - Kahn's sort: `remaining[node] == 0`일 때만 처리, 각 노드 정확히 1회 처리
   - → [[issues/echarts-sankey-oracle-decimal-tier-detection]]

5. **시스템 프롬프트 개선**
   - Sankey SQL 규칙 4줄 → 2줄 압축 (정보 손실 없음)
   - 섹션 헤더 영어 통일: `"## Visualization Request Guidelines"`, `"## ⚠️ CRITICAL RULES ⚠️"`, `"### 1. SQL Generation"`, `"### 2. Language & Response Policy"`
   - `runner_type != "Standard"` 조건 추가 (Standard 문구 노출 방지)
   - combo 가이드라인 추가: `x (category), y (bar series), value (line series on secondary y-axis)`
   - Sankey 규칙 위치 결정: system prompt에 압축 포함 (tool description/enhancer 대안 기각)

6. **커밋 정리 및 PR #45 생성**
   - `git reset --soft HEAD~2` 후 기능 단위로 재커밋
   - scatter label, combo, prompt 개선을 별도 커밋으로 분리
   - PR #45: `refactor/chart-visualization` → `main`

## 핵심 결정

- **Sankey 규칙을 system prompt에 포함:** LLM이 시각화 도구 호출 전에 SQL을 생성하므로, `visualize_data` tool description이나 enhancer에 넣으면 타이밍이 늦다. system prompt에 2줄 압축 포함이 최선.
  → ADR: [[decisions/008-sankey-column-order-architecture]]

- **Sankey 컬럼 순서 = 흐름 방향:** x/y 파라미터를 사용하지 않고 SELECT 컬럼 순서가 자동으로 left→right tier 순서가 됨. LLM에게 이 규칙을 명확히 안내.

- **per-item label 방식:** ECharts는 series-level label 외에 `data[i].label`로 개별 포인트 라벨 오버라이드 가능. 이를 활용해 scatter 각 점에 컬럼 값 표시.

## 배운 것

- **ECharts 이중 y축:** `yAxis`를 배열로 정의하고 각 series에 `yAxisIndex` 지정. `axisPointer: {type: "cross"}`로 크로스헤어 연동.
- **Kahn's topological sort vs BFS:** DAG 최장경로 깊이 계산 시 BFS는 중복 큐 삽입 문제 발생. Kahn's sort(진입 차수 0인 노드 순차 처리)가 정확.
- **`coerce_numeric` 위치 문제:** DataFrame 정규화와 차트 타입 해석은 분리되어야 함. 타입 해석을 먼저 수행해야 타입별 정규화 옵션 적용 가능.

## 문제 & 해결

- **문제:** Oracle Sankey에서 연도 컬럼('2023')이 numeric으로 변환되어 티어 컬럼으로 인식 안 됨
- **원인:** `_normalize_df`의 `coerce_numeric=True` 기본값이 sankey 티어 컬럼을 int로 변환
- **해결:** sankey 타입 먼저 resolve 후 `coerce_numeric=False`로 정규화
  → 이슈: [[issues/echarts-sankey-oracle-decimal-tier-detection]]

- **문제:** Sankey 노드 depth 계산 오류 (BFS 중복 큐)
- **원인:** neighbor를 큐에 삽입할 때 중복 방지 없음
- **해결:** Kahn's topological sort로 교체

- **문제:** UNION ALL에서 ORA-01790 (컬럼 타입 불일치)
- **원인:** LLM이 첫 번째 UNION ALL 브랜치에 COUNTRY_ID(numeric), 두 번째에 CHANNEL_DESC(varchar) 사용
- **해결:** system prompt에 규칙 추가 — ID/_CD/_KEY/_NO 컬럼 금지, 타입 불일치 시 TO_CHAR() 사용

## 다음 할 일

- [ ] PR #45 머지 (refactor/chart-visualization)
- [ ] CALENDAR_YEAR 연도 정수 → scatter 오선택 버그 수정

## 효과적이었던 프롬프트

```
지금 bar, line 같이 나오는 차트 지원이 안 되나봐
```
→ 간결한 요구 → combo 차트 전체 구현 트리거
