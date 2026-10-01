---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-25
resolved: false
root-cause: "_preprocess_df 가 쉼표로 묶인 y 를 원본 문자열 그대로 컬럼명과 비교해 집계·정렬 분기를 통째로 건너뜀"
tags: [chart, aggregation, sorting, code-review]
---

# 다중 컬럼 y 를 주면 agg·sort_by 가 조용히 무시됨

> 코드 리뷰에서 나온 지적. 리뷰어는 재현했다고 보고했으나 직접 확인하지는 않았다.

## 증상

에러가 없다. 차트는 그려지는데 값이 틀리다.

- `agg='sum'` 은 `_multi_series` 가 다시 집계해서 우연히 맞지만, `agg='mean'`·`max` 는 그대로 사라진다.
- `sort_by='y'` + `top_n=10` 이 정렬 없이 `df.head(10)` 으로 떨어져, 상위 10개가 아니라 결과의 앞 10행이 나온다.

## 환경

- `src/dna/tools/dna_visualize_data.py:624`, `:630`
- `y='매출,비용'` 처럼 쉼표로 여러 컬럼을 준 경우

## 근본 원인

```python
if args.y in df.columns: ...   # y 가 '매출,비용' 이면 항상 False
sort_col = ...                  # 같은 이유로 빗나감
```

다중 컬럼 `y` 를 도입하면서 `_multi_series` 쪽만 리스트를 다루도록 고쳤고, 그 앞단인 `_preprocess_df` 는 단일 컬럼 전제 그대로 남았다.

조용히 틀린 값을 내므로 크래시보다 발견이 늦다.

## 해결 방법

미정. `_preprocess_df` 에서도 `resolve_columns` 로 `y` 를 리스트로 풀고, 집계·정렬을 그 리스트 기준으로 수행한다.
