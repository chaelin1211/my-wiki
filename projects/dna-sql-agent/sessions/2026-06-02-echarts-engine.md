---
type: session-log
project: dna-sql-agent
date: 2026-06-02
duration: ~4h
focus: "ECharts 차트 엔진 추가 및 동적 스키마 구현"
tools-used: [claude-code]
outcome: success
---

# 2026-06-02 — ECharts 차트 엔진 추가

## 목표

- ECharts를 세 번째 차트 엔진으로 추가
- 엔진별 지원 차트 타입 동적 관리
- PR #39 생성

## 수행한 작업

1. `ChartConfig.engine` regex에 `echarts` 추가
2. `dna/integrations/echarts/` 패키지 신규 생성
3. `EChartsChartGenerator` 구현
   - bar, line, scatter, pie, heatmap, table, sankey, area, stackedBar, stackedArea, spline 지원
   - `_make_series_obj`로 타입별 옵션 주입 (areaStyle, stack, smooth)
   - heatmap: x/y 카테고리 기반 `[x_idx, y_idx, value]` 구조, visualMap, 중복 셀 합산
   - sankey: nodes/links 구성, source/target/value 분리
4. `dna_visualize_data.py` 수정
   - `CHART_TYPES_BY_ENGINE` 도입 — plotly/devextreme/echarts 지원 타입 분리
   - `get_args_schema()` 동적 생성 (`create_model` 활용)
   - `description` property 동적화
   - `value_col` 파라미터 추가 (heatmap x/y/value 명시적 분리)
   - `{"option": ...}` 래핑 — FE bookmark 감지 규약
5. 코드 리뷰 후 정리
   - 미사용 변수 제거 (series_type, x_data)
   - title 파라미터 제거 (FE 카드 헤더 처리로 이중 표시 방지)
   - defaultdict 모듈 상단으로 이동
   - `pd.to_datetime(format="mixed")` 추가
   - `_validate_columns`에 value_col 검증 추가
6. PR #39 생성 및 머지 대기

## 핵심 결정

- **ECharts table 처리:** `{"option": {"dataSource": ...}}` 래핑 후 FE에서 `option.dataSource` 감지해 별도 렌더링 (옵션 B) → ADR: [[decisions/006-echarts-engine-design]]
- **엔진별 동적 스키마:** `get_args_schema()`에서 `create_model`로 Literal 동적 생성 — LLM이 현재 엔진 타입만 인식
- **value_col 분리:** heatmap에서 y_col을 카테고리 축으로, 값은 value_col로 명시적 분리

## 배운 것

- `create_model`로 Pydantic 모델을 런타임에 동적 생성 가능 → LLM 툴 스키마 동적 제어
- ECharts heatmap은 `[x_idx, y_idx, value]` 3-element 배열 필수 — category data는 index로 변환
- `pd.to_datetime(format="mixed")` — pandas 2.0부터 format 미지정 시 UserWarning 발생

## 문제 & 해결

- **문제:** heatmap y축에 숫자만 나옴
- **원인:** GENDER × AGE_GROUP × PROD_CATEGORY 데이터에서 같은 (x,y) 셀에 M/F 두 행이 중복 매핑
- **해결:** `defaultdict`로 합산 집계 처리
  → 이슈: [[issues/echarts-heatmap-duplicate-cell]]

## 다음 할 일

- [ ] PR #39 리뷰 및 머지
- [ ] FE: ECharts 렌더러 구현 (EChartsBlock 컴포넌트)
- [ ] 팔레트 공통 config로 추출 (현재 3개 엔진에 하드코딩)
