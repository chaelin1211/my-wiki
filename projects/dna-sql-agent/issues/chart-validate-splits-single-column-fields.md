---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-25
resolved: false
root-cause: "다중 컬럼을 받는 y 때문에 도입한 쉼표 분리를 x·color·value 에도 일괄 적용해, 잘못된 입력이 검증을 통과함"
tags: [chart, validation, llm-tool, code-review]
---

# x 에 쉼표를 넣어도 검증을 통과해 안내 없는 KeyError 로 떨어짐

> 코드 리뷰에서 나온 지적. 리뷰어는 재현했다고 보고했으나 직접 확인하지는 않았다.

## 증상

`x='REGION,YEAR', y='QTY'` 요청 시:

```
Error creating visualization: 'REGION,YEAR'
```

이전에는 이렇게 나왔다.

```
Column 'REGION,YEAR' not found. Available columns: [...]
```

## 환경

- `src/dna/tools/dna_visualize_data.py:715`

## 근본 원인

`_validate_columns` 가 모든 필드를 쉼표로 분리한다. 다중 컬럼을 실제로 받는 건 `y`(그리고 combo 의 `value`)뿐인데, `x`·`color` 까지 분리되면서 `'REGION,YEAR'` 가 `REGION` 과 `YEAR` 두 개로 쪼개져 검증을 통과한다. 실패는 나중에 plotly 안에서 `KeyError` 로 터진다.

검증기의 값어치가 에러 메시지에 있다는 점에서 손실이 크다. LLM 이 받던 "이 컬럼 없음 + 사용 가능한 컬럼 목록" 이라는 자기수정 단서가 사라진다.

## 해결 방법

미정. 리스트를 받는 필드에만 쉼표 분리를 적용한다.

## 관련

- [[knowledge/patterns/llm-tool-schema-mirrors-implementation]]
