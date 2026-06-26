---
type: decision-record
project: dna-sql-agent
date: 2026-06-26
status: accepted
superseded-by: ""
tags: [visualization, map, geojson, leaflet]
---

# ADR-018: GeoJSON 지도 시각화 아키텍처

## 맥락

위경도·지명·노선(출발→도착) 데이터를 지도로 보고 싶다는 요구. 기존 visualize 도구는 평면 차트(bar/line/pie/heatmap/sankey)만 지원했다. 지도 데이터 전달·렌더·영속화 방식을 정해야 했다.

## 선택지

### 옵션 A: 데이터셋 ID 참조 + 프론트가 API로 동적 조회
- **장점:** 대용량에 유리(bbox 단위 로드)
- **단점:** 북마크/대시보드 스냅샷 자기완결성 깨짐(원본 데이터 살아있어야 함), 구현 복잡

### 옵션 B: 백엔드가 GeoJSON 스냅샷을 컴포넌트에 임베드
- **장점:** 다른 차트와 동일 라이프사이클(북마크/대시보드 자기완결), 단순
- **단점:** 초대용량은 페이로드 큼

## 결정

**옵션 B(임베드 스냅샷)를 기본으로 하고, bbox 동적 조회 API는 대용량 옵션으로만 둔다.**

- `chart_type='map'` 한 타입으로 3형태 처리(엔진 무관, 엔진 선택 이전 분기): **흐름(flow) → 점(point) → 지명(choropleth)** 순 판별
- **point**: lat/lon → 임베드 GeoJSON, 모든 컬럼 properties
- **choropleth**: region(지명/국가) → 내장 경계 폴리곤 조인 색칠(한국 시도·세계 국가, 한글/영문/ISO3 별칭·레벨 자동판별)
- **flow**: dep/arr 좌표쌍 → LineString + 허브 점
- **label/color/value 등 필드 매핑은 LLM이 선정**(x/y처럼). 프론트·서버 자동추론 휴리스틱은 두지 않음
- 프론트는 Leaflet(react-leaflet)로 렌더, `field_mapping`만 보고 표시

## 근거

- 북마크·대시보드가 이미 컴포넌트 스냅샷을 저장하므로, 지도도 같은 방식이라야 일관·자기완결적.
- 한 `chart_type='map'`으로 묶으면 엔진(plotly/echarts/devextreme)과 무관하게 동작하고 도구 표면이 단순.
- 필드 선정을 LLM에 맡기는 게 다른 차트와 일관(쿼리 결과를 본 주체가 LLM).

## 결과

- 경계 데이터는 단순화해 내장 → 외부 의존·네트워크 불필요(오프라인).
- flow color 미지정 시 출발지 폴백. 방향(출/도착) 같은 행 단위 플래그를 color로 쓰지 않도록 도구 설명으로 유도(데이터 종속 표현은 배제, 일반 원칙으로).
- LLM 컬럼명 케이스 불일치 대비 백엔드에서 대소문자 무시 매칭(`_resolve_col`).
- 재검토 시점: 초대용량(수십만 포인트) 요구 시 bbox API 본격화.
- 영향: `dna_visualize_data.py`, `geojson_service.py`, `region_boundary.py`, `bookmarks/routes.py(render)`, 프론트 `map-block-impl.tsx` 등.

## 참고 자료

- PR 백엔드 #81 / 웹 #60
- [[015-bookmark-dashboard-architecture]]
