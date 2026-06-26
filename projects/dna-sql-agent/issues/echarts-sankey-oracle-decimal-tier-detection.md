---
type: issue-record
project: dna-sql-agent
date: 2026-06-08
status: resolved
tags: [echarts, sankey, oracle, pandas]
---

# ECharts Sankey — Oracle Decimal 티어 컬럼 오감지

## 증상

Oracle DB에서 연도 데이터('2023', '2024', '2025')를 sankey 티어 컬럼으로 사용할 때,
해당 컬럼이 categorical_cols로 인식되지 않아 sankey 링크 생성 시 "No categorical columns found" 오류 발생.

## 환경

- Oracle DB (숫자 문자열 값)
- ECharts sankey 차트
- `chart_generator.py` `_normalize_df` 함수
- pandas `pd.to_numeric(errors='coerce')` 변환

## 시도한 것들

- 쿼리에서 TO_CHAR() 적용 → DB 레벨에서 해결 안 됨 (이미 VARCHAR인데도 pandas가 변환)
- `_build_sankey` 내부에서 컬럼 타입 재확인 → 이미 변환된 후라 의미 없음

## 근본 원인

`_normalize_df(coerce_numeric=True)` 기본값으로 호출 시,
pandas `pd.to_numeric(errors='coerce')`가 '2023', '2024' 같은 숫자 문자열을 모두 int/float로 변환.

이후 `categorical_cols = [c for c in df.columns if not pd.api.types.is_numeric_dtype(df[c])]`에서
변환된 컬럼이 numeric으로 분류되어 sankey 티어 컬럼 후보에서 제외됨.

추가 문제: `_resolve_chart_type`이 `_normalize_df` **이후**에 호출되어,
sankey 타입을 알기 전에 이미 numeric 변환이 완료된 상태였음.

## 해결 방법

1. `_resolve_chart_type`을 `_normalize_df` **이전**으로 이동
2. chart_type이 sankey이면 `_normalize_df(coerce_numeric=False)`로 호출
3. `coerce_numeric=False`일 때는 `pd.to_numeric` 변환 스킵

```python
# chart_generator.py (변경 후)
chart_type = self._resolve_chart_type(chart_type, df)  # 먼저 해석
df = self._normalize_df(df, coerce_numeric=(chart_type != "sankey"))  # 타입별 정규화
```

## 예방책

- 차트 타입별로 다른 전처리가 필요한 경우, 항상 타입 해석 → 전처리 순서 유지
- sankey처럼 "숫자처럼 보이는 카테고리 값"을 다루는 차트는 명시적으로 coerce_numeric=False 적용

## 관련 페이지

- [[decisions/008-sankey-column-order-architecture]]
- [[sessions/2026-06-08-echarts-chart-visualization-refactor]]
