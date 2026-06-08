---
type: knowledge
tags: [echarts, tooltip, json, frontend]
created: 2026-06-05
---

# ECharts Tooltip — JSON 환경에서의 포맷터 패턴

## 배경

ECharts를 Python 백엔드에서 JSON option으로 생성할 때, JS 함수를 사용할 수 없어 tooltip formatter 선택지가 제한된다.

## 템플릿 변수 동작 정리

| 변수 | 동작 | 주의 |
|------|------|------|
| `{a}` | 시리즈명 | - |
| `{b}` | 데이터 name 필드 | **HTML escape 처리됨** — `<b>` 태그가 텍스트로 출력 |
| `{c}` | 데이터 값 (배열이면 전체 join) | - |
| `{c0}`, `{c1}` | **axis trigger 다중 시리즈**에서만 유효 | item trigger 단일 시리즈에서 미동작 |
| `{d}` | 퍼센트 (pie만) | - |

## Scatter / 다차원 데이터 툴팁 — 권장 패턴

### 문제
`data: [[x, y], ...]` 배열 포맷에서 개별 dimension 접근 불가 (JS 함수 없이).

### 해결: `{value, name}` 객체 포맷 + `{b}` + `white-space: pre-line`

```python
# Python 백엔드
tooltip = {
    "trigger": "item",
    "formatter": "{b}",
    "extraCssText": "white-space: pre-line;",
}

data = [
    {
        "value": [float(x), float(y)],
        "name": f"x_col: {x_val}\ny_col: {y_val}",  # \n으로 줄바꿈
    }
    for ...
]
```

- `{b}` → `name` 필드 그대로 출력
- `white-space: pre-line` → `\n`을 실제 줄바꿈으로 렌더
- HTML 태그 없이 가독성 확보

### 왜 HTML이 안 되는가

ECharts는 `{b}` placeholder 치환 시 name 값을 HTML escape 처리한다.
`<b>col</b>` → `&lt;b&gt;col&lt;/b&gt;` 로 출력됨.
HTML 렌더링은 JS function formatter만 가능.

## Bubble Chart — visualMap으로 symbolSize 매핑

```python
# data: {value: [x, y, size], name: "..."}
"visualMap": {
    "show": False,
    "type": "continuous",
    "min": s_min,
    "max": max(s_max, s_min + 1),  # min==max 방어
    "dimension": 2,                 # value[2] = size 값
    "seriesIndex": 0,
    "inRange": {"symbolSize": [5, 50]},
}
```

- `show: False` — 슬라이더 UI 숨기고 내부 매핑만 동작
- `dimension: 2` — 배열의 3번째 값(index 2) 기준
- size 데이터는 반드시 `float` 타입 보장 필요 (문자열이면 매핑 실패)

## Axis Trigger (cartesian) — axisPointer 타입

```python
# bar계열: shadow, line계열: line
axis_pointer_type = "shadow" if chart_type in ("bar", "stackedBar", "histogram") else "line"
tooltip = {"trigger": "axis", "axisPointer": {"type": axis_pointer_type}}
```

## confine

`confine: true` → 툴팁이 차트 영역 밖으로 나가지 않음. 모든 차트에 적용 권장.
JSON 기반 시스템에서는 프론트에서 기본값으로 주입하는 것이 깔끔함:

```ts
tooltip: { confine: true, ...option.tooltip }
```
