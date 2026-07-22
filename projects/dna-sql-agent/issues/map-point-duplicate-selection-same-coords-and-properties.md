---
type: troubleshooting
project: dna-sql-agent
date: 2026-07-09
resolved: true
root-cause: "프론트 featureId가 좌표+properties(JSON.stringify) 조합으로 id를 만드는데, properties는 LLM이 조회한 컬럼만 담겨서 좌표+표시값이 완전히 같은 행이면 id가 충돌"
related: [projects/dna-sql-agent-web]
tags: [geojson, map-visualization, react, frontend]
---

# 지도 point 시각화 — 좌표+표시 컬럼이 같은 행이 있으면 여러 점이 함께 선택됨

> 새 이슈 파일명: `map-point-duplicate-selection-same-coords-and-properties.md`

## 증상

지도(point) 시각화의 좌측 데이터 목록에서 이름이 같은 점들이 묶여 번호(#1, #2...)로
표시되는데, 번호가 여러 개인데도 그중 하나를 클릭하면 같은 이름 묶음의 다른 점들까지
전부 같이 선택 상태가 됨(지도 위 마커도 함께 하이라이트).

## 환경

- **OS:** -
- **런타임:** Next.js(프론트) + FastAPI(백엔드)
- **관련 패키지:** leaflet, geojson
- **재현 조건:** LLM이 조회한 표시 컬럼(좌표 + label/color 등)이 두 행 이상에서
  완전히 동일할 때(예: 같은 지점의 국내선/국제선처럼 좌표는 같고 구분 컬럼은
  아예 안 뽑아온 경우)

## 시도한 것들

1. ✅ 프론트 `featureId()`가 `point:${lat},${lon}#${JSON.stringify(properties)}`로
   id를 만드는 걸 확인 — `properties`는 SQL이 SELECT한 컬럼만 담기므로, 사용자
   질문에 따라 LLM이 구분 가능한 컬럼(PK, 시간대 등)을 아예 안 뽑아올 수 있음 →
   그러면 좌표+properties가 통째로 같은 행이 실제로 존재해 id가 겹침

## 근본 원인

`Feature.id`(GeoJSON 표준 필드)를 서버가 내려주지 않고, 프론트가 좌표+properties로
id를 "합성"하고 있었다. properties는 LLM이 어떤 컬럼을 조회했는지에 전적으로
의존하므로, 조회 컬럼이 부족하면 서로 다른 행이 우연히 동일한 id를 갖게 된다.

## 해결 방법

백엔드(`src/dna/visualizations/geojson_service.py::dataframe_to_map_payload`)가
각 point Feature에 **행 위치(i) 기반 `id`**를 항상 부여하도록 수정:

```python
features = [
    {
        "type": "Feature",
        "id": i,
        "geometry": {"type": "Point", "coordinates": [...]},
        "properties": records[i],
    }
    for i in range(len(df))
]
```

프론트(`components/map-block-impl.tsx::featureId`)는 `f.id`가 있으면 그걸
우선 사용하고, 없으면(구버전 캐시/북마크 스냅샷) 기존 좌표+속성 방식으로 폴백:

```ts
if (f.id != null) return `point:id:${f.id}`
// 폴백: point:${lat},${lon}#${JSON.stringify(p)}
```

## 예방책

- id는 "표시용 데이터(properties)"가 아니라 "서버가 아는 안정적인 행 식별자"로
  만들어야 한다는 걸 다른 시각화 payload(흐름선 등)에도 적용할지 검토할 것
  (흐름선은 좌표쌍까지 포함해 id를 만들어서 상대적으로 충돌 위험이 낮지만,
  완전히 안전하진 않음)
- LLM이 조회하는 컬럼 수에 의존하는 프론트 로직(id, 라벨 등)은 항상 "조회
  컬럼이 부족한 경우"를 가정하고 설계할 것

## 관련 페이지

- [[projects/dna-sql-agent/decisions/018-geojson-map-visualization]]
