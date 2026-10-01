---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-25
resolved: false
root-cause: "value 해석을 호출부에서 빼면서 소비처마다 resolve_column 을 넣었는데 _build_sankey 만 누락"
tags: [chart, echarts, sankey, code-review]
---

# ECharts sankey — value 컬럼명을 대소문자 그대로 찾아 KeyError

> 코드 리뷰에서 나온 지적. 리뷰어는 재현했다고 보고했으나 직접 확인하지는 않았다.

## 증상

```
KeyError: 'Column not found: amount'
```

## 환경

- `src/dna/tools/dna_visualize_data.py:972` (호출부), `src/dna/integrations/echarts/chart_generator.py:308` (소비처)
- 컬럼이 `SRC` / `DST` / `AMOUNT` 인 결과에 `value='amount'`

## 근본 원인

`_generate_echarts` 가 `value=self._resolve_col(args.value, df)` 에서 `value=args.value` 로 바뀌었다. 해석 책임이 각 `_build_*` 로 옮겨갔는데 `_build_heatmap`·`_build_combo` 만 `resolve_column` 을 쓰고 `_build_sankey` 는 넘어온 문자열을 컬럼 라벨로 직접 쓴다.

이전에는 `_resolve_col` 이 대소문자를 무시하고 매칭했고, 못 찾으면 `None` 을 돌려줘 마지막 숫자 컬럼으로 안전하게 떨어졌다. 그래서 예전에는 그려지던 요청이 이제 터진다.

## 해결 방법

미정. `_build_sankey` 진입부에서 `resolve_column(value, df)` 를 적용해 다른 빌더와 맞춘다.

## 관련

- [[projects/dna-sql-agent/issues/echarts-sankey-dag-cycle]]
