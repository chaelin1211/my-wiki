---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-30
resolved: true
root-cause: "display_cols가 from/to 라벨 컬럼을 제외하는데 flow color 기본값이 from_label이라 color 컬럼이 properties에서 통째로 누락"
related: [flowmap-list-grouping]
tags: [map, flow, legend, regression]
---

# flow map 범례가 안 뜸 (color == from_label일 때)

## 증상

flow 지도에서 `color`를 지정해도(특히 출발지 컬럼) **범례가 안 나오고 라인 색도 한 가지로만** 나옴. 코드 컬럼(DEPARTURE_ARPT)이든 이름 컬럼(DEP_NAME)이든 범례 누락.

## 환경

- **런타임:** Python / FastAPI
- **관련 파일:** `src/dna/visualizations/geojson_service.py` (`dataframe_to_flow_payload`), `src/dna/tools/dna_visualize_data.py` (`_try_flow_payload`)
- **재현 조건:** flow map에서 `color`가 `from_label`과 동일(= 기본 동작)

## 시도한 것들

1. ❌ 도구 설명에서 "Avoid ID/code columns" 때문인가 의심 (설명 문제 아님)
2. ✅ payload를 직접 찍어 라인 properties 확인 → `color` 키 자체가 없음

## 근본 원인

"흐름선에 부가 컬럼 통과" 리팩터에서 라인 properties를 만들 때 `display_cols`(좌표/끝점라벨 제외 컬럼)만 순회하도록 바꿨다. 그런데 `_try_flow_payload`는 `color = args.color or from_label`로 **color 기본값이 from_label**이다. from_label 컬럼은 `display_cols`에서 제외되므로 color도 함께 빠져 **라인에 카테고리 속성이 안 실림** → 프론트 `legendCategories`가 빈 값('')만 모아 범례 미표시, `colorOf`도 첫 색으로 폴백.

```python
# 라인 props 결과 (버그): color 키 없음
{'from': '김포', 'to': '제주', 'FLY_COUNT': 100.0}
```

## 해결 방법

color/value가 from/to 라벨과 같아 `display_cols`에서 빠졌으면 **별도로 보강**:

```python
for c in display_cols:
    ...  # 기존 통과 로직
# color/value가 from/to 라벨과 같아 빠졌으면 보강(flow는 color 기본값이 from_label)
if has_color and color not in props:
    props[color] = str(row[color])
if has_value and value not in props:
    _v = row[value]
    props[value] = None if pd.isna(_v) else float(_v)
```

→ 라인 props에 `DEP_NAME` 포함, `categories=['김포','제주']`, 범례 정상.

## 예방책

- "모든 컬럼 통과" 류 리팩터 시, **의미 있는 매핑 컬럼(color/value)** 은 통과 목록과 무관하게 항상 보장할 것.
- 프론트 범례는 라인의 `props[colorField]` 존재 + 카테고리 2종 이상일 때만 뜬다는 점을 기억.

## 관련 페이지

- [[decisions/018-geojson-map-visualization]]
