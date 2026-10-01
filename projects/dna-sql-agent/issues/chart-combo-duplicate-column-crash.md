---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-25
resolved: false
root-cause: "combo 의 라인 컬럼 폴백이 이미 막대로 쓰인 컬럼을 재사용해, groupby 대상에 같은 이름이 두 번 들어감"
tags: [chart, plotly, combo, code-review]
---

# plotly combo — 라인 컬럼 폴백이 막대 컬럼과 겹치면 크래시

> 코드 리뷰에서 나온 지적. 리뷰어는 재현했다고 보고했으나 직접 확인하지는 않았다.

## 증상

```
DuplicateError: Expected unique column names, got: 'QTY' 2 times
```

도구는 "Error creating visualization" 을 돌려준다.

## 환경

- `src/dna/tools/dna_visualize_data.py:753`
- 숫자 컬럼이 하나뿐인 결과에 `chart_type='combo', x='LINE', y='QTY'`
- 또는 LLM 이 `y='QTY', value='QTY'` 처럼 같은 컬럼을 양쪽에 준 경우

## 근본 원인

```python
line_cols = remaining[:1] or [bar_cols[-1]]
```

`remaining` 이 비면 막대 컬럼을 그대로 라인 컬럼으로 쓴다. 그 값이 `secondary_cols` 에 들어가고, `_dual_axis` 의 `df.groupby(x)[primary_cols + secondary_cols]` 에서 같은 컬럼명이 중복된다.

`y` 와 `value` 의 필드 설명이 다중 컬럼을 권하는 방향으로 바뀌면서 LLM 이 이 조합을 만들기 쉬워졌다.

## 해결 방법

미정. `line_cols` 를 `bar_cols` 기준으로 중복 제거하고, 남는 컬럼이 없으면 combo 를 포기하고 단일 축 차트로 떨어뜨리는 방향.

## 관련

- [[projects/dna-sql-agent/issues/echarts-combo-duplicate-series]] — echarts 쪽의 같은 성격 문제(크래시 없음)
