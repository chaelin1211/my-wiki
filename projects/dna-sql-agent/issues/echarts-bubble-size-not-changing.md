---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-05
resolved: true
root-cause: "visualMap 에 넘긴 data 배열의 dimension 2 값이 문자열이라 크기 매핑이 적용되지 않음"
related: []
tags: [echarts, chart, visualization, dtype]
---

# ECharts 버블 차트의 버블 크기가 전부 동일하게 렌더됨

## 증상

scatter/bubble 차트를 그렸을 때 값이 서로 다른데도 모든 버블이 같은 크기로 나온다.
오류는 발생하지 않고 조용히 기본 크기로만 그려진다.

## 환경

- `dna-sql-agent` — 차트 생성 경로
- ECharts scatter 시리즈 + `visualMap` 으로 symbolSize 매핑

## 근본 원인

ECharts `visualMap` 의 `dimension` 은 data 배열의 `value[N]` 인덱스를 기준으로
크기를 매핑한다. 이때 dimension 2 자리의 값이 **문자열 타입**으로 들어가면
수치 범위를 계산하지 못해 매핑이 적용되지 않는다.

DB 결과를 DataFrame 으로 받는 과정에서 해당 컬럼이 object dtype 으로 남아
문자열이 그대로 전달된 것이 원인이다.

## 해결 방법

차트 데이터 구성 시 크기 매핑 대상 컬럼을 수치형으로 강제 변환한다.

```python
df[size_col] = pd.to_numeric(df[size_col], errors="coerce")
df = df.dropna(subset=[size_col])
```

`pd.to_numeric` + `dropna` 로 float 을 보장한 뒤 `visualMap` 에 전달한다.

## 예방책

- 시각화 라이브러리에 넘기는 수치 필드는 **넘기기 직전에 dtype 을 보장**할 것.
  ECharts 는 타입이 맞지 않아도 오류 없이 기본값으로 그리므로 조용히 틀린다
- `np.float64` 는 Python `float` 의 subclass 라 `isinstance(x, float)` 로 검증 가능

## 관련 페이지

- [[projects/dna-sql-agent/sessions/2026-06-05-echarts-scatter-bubble-refactor]]
- [[decisions/006-echarts-engine-design]]
- [[issues/echarts-sankey-dag-cycle]]
