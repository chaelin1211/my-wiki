---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-25
resolved: false
root-cause: "value 가 없을 때 라인 시리즈를 numeric_cols[1] 로 고르는데, 다중 컬럼 y 에서는 그것이 이미 막대인 경우가 흔함"
tags: [chart, echarts, combo, code-review]
---

# ECharts combo — 같은 컬럼이 막대와 선으로 동시에 그려짐

> 코드 리뷰에서 나온 지적. 리뷰어는 재현했다고 보고했으나 직접 확인하지는 않았다. 심각도 낮음.

## 증상

크래시는 없다. 범례에 같은 지표가 두 번 나오고, 한 값이 주축 막대와 보조축 선으로 중복해 그려진다.

## 환경

- `src/dna/integrations/echarts/chart_generator.py:274`
- `y='매출,비용'` 처럼 다중 컬럼을 주고 `value` 를 생략한 경우

## 근본 원인

`value` 가 없으면 라인 시리즈를 `numeric_cols[1]` 로 고른다. 다중 컬럼 `y` 가 생기기 전에는 그 자리가 보통 막대에 안 쓰인 컬럼이었지만, 지금은 `비용` 처럼 이미 막대로 그려진 컬럼이 걸린다.

각 컬럼을 따로 집계하므로 plotly 쪽처럼 크래시로 이어지지는 않는다.

## 해결 방법

미정. `bar_cols` 에 없는 첫 숫자 컬럼을 고르고, 없으면 라인 시리즈를 생략한다.

## 관련

- [[projects/dna-sql-agent/issues/chart-combo-duplicate-column-crash]] — plotly 쪽의 같은 성격 문제(이쪽은 크래시)
