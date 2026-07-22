---
type: knowledge
category: troubleshooting
tags: [python, pandas, json, datetime, serialization]
related: ["projects/dna-sql-agent/issues/flowmap-legend-color-equals-from-label"]
---

# pandas: df.to_json()이 datetime을 epoch 밀리초(숫자)로 직렬화

## 증상

DataFrame을 JSON으로 내보내 프론트로 전달했더니 datetime 컬럼이 날짜가 아니라 **큰 숫자**(예: `1782000000000`)로 표시됨. 화면에서 천단위 콤마까지 붙어 숫자처럼 보임.

## 원인

`DataFrame.to_json(orient="records")`의 기본 `date_format`은 **`epoch`(밀리초 정수)** 다. (`orient="table"`만 예외적으로 `iso`)

```python
df = pd.DataFrame({"tm": pd.to_datetime(["2026-06-29T21:36:31"])})
df.to_json(orient="records")
# '[{"tm":1782000000000}]'  ← 숫자!
```

## 해결

`date_format="iso"`를 명시한다.

```python
df.to_json(orient="records", date_format="iso")
# '[{"tm":"2026-06-29T21:36:31.000"}]'
```

개별 셀을 수동 변환하는 경로에서는 `Timestamp`/`datetime`을 `isoformat()`으로:

```python
def _cell_jsonsafe(v):
    ...
    if hasattr(v, "isoformat"):   # Timestamp/datetime/date/time
        return v.isoformat()
    return v
```

## 예방책

- df → JSON으로 프론트에 넘기는 모든 경로에서 `date_format="iso"` 기본 적용.
- 같은 데이터라도 직렬화 경로가 둘 이상이면(예: `to_json` 경로 vs 수동 dict 경로) **양쪽 다** datetime 처리 확인.

## 관련 페이지

- [[knowledge/troubleshooting/json-nan-serialization]]
