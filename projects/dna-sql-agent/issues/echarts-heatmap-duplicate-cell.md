---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-02
resolved: true
root-cause: "GENDER × AGE_GROUP × PROD_CATEGORY 등 3차원 데이터에서 같은 (x,y) 셀에 여러 행이 매핑되어 마지막 값으로 덮어씌워짐"
tags: [echarts, heatmap, aggregation]
---

# ECharts Heatmap — 같은 셀에 여러 값 중복 표시

## 증상

heatmap에서 특정 셀에 값이 겹쳐 보이거나 일부 조합이 누락됨.

## 환경

- 데이터: GENDER(M/F) × AGE_GROUP × PROD_CATEGORY × TOTAL_SALES
- x=AGE_GROUP, y=PROD_CATEGORY로 heatmap 요청 시 GENDER가 무시됨

## 근본 원인

`EChartsChartGenerator._build_heatmap`에서 data를 리스트 컴프리헨션으로 생성 시, 동일한 `(x_idx, y_idx)` 쌍이 여러 번 나타나면 ECharts가 마지막 값만 표시함.

## 해결 방법

```python
from collections import defaultdict
agg: dict = defaultdict(float)
for _, row in df.iterrows():
    agg[(x_cats.index(str(row[x])), y_cats.index(str(row[y])))] += float(row[value_col])

data = [[xi, yi, _fmt(v)] for (xi, yi), v in agg.items()]
```

동일 셀 값을 합산하여 하나의 셀로 집계.

## 예방책

heatmap 데이터 구성 시 축으로 사용하지 않는 차원(GENDER 등)이 있으면 `value_col`로 미리 집계된 데이터를 사용하거나, 백엔드에서 자동 합산.
