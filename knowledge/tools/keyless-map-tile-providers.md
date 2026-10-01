---
type: knowledge
category: tools
date: 2026-09-16
tags: [map, tiles, leaflet, maplibre]
---

# 키 없이 쓸 수 있는 지도 타일 제공처 (2026-09 기준)

웹 지도의 배경(타일)은 외부 제공처에 의존한다. **제공처 정책이 바뀌면 코드를 안 고쳐도 화면이 깨진다.** 키·계정 없이 쓸 수 있는 선택지와 각각의 함정을 실측 기준으로 정리한다.

## 래스터 (서버가 그려 준 PNG — Leaflet `TileLayer` 로 바로 사용)

| 제공처 | 키 | 주의 |
|---|---|---|
| OSM 공식 `tile.openstreetmap.org` | 불필요 | `Referer` 없는 요청은 403 `Access blocked` **그림**을 반환. 브라우저는 정상, curl 테스트만 실패한다. 대량 트래픽은 사용 정책 위반 |
| Esri `Canvas/World_Light_Gray_Base`·`World_Dark_Gray_Base` | 불필요 | **지역마다 보유 줌이 다름.** 한국 기준 밝은 z13·어두운 z16 까지, 그 이상은 "Map data not yet available" 그림. 지명은 별도 `..._Reference` 레이어 |
| Esri `World_Imagery` (위성) | 불필요 | 타일 좌표가 `{z}/{y}/{x}` 순서 |
| CARTO `basemaps.cartocdn.com` | **필요해짐** | 키 없으면 타일에 `API KEY REQUIRED` 인쇄. 무료는 월 500만 요청이고 상업적 사용은 엔터프라이즈 라이선스 논의 대상 |

## 벡터 (도형·속성 데이터 — 브라우저가 스타일대로 직접 그림)

- **OpenMapTiles 스타일**(Positron, Dark Matter 등) 원본은 타일·폰트를 MapTiler 에서 받으므로 **키가 필요**하다.
- **OpenFreeMap**(`tiles.openfreemap.org`)이 같은 스타일을 키·한도 없이 호스팅한다. 상업적 사용 허용, SLA 없음, 표기는 `OpenFreeMap © OpenMapTiles Data from OpenStreetMap`. 주간 planet MBTiles 를 받아 자체 호스팅도 가능하다.
- 대가: Leaflet 으로는 못 그린다. `maplibre-gl`(gzip 약 293KB, Leaflet 은 41KB) + `@maplibre/maplibre-gl-leaflet` 브리지가 필요하고 **WebGL 이 필수**다. 지도 1개가 WebGL 컨텍스트 1개를 쓰므로 한 화면에 지도가 많으면 브라우저 상한(Chrome 약 16개)에 걸린다. 브리지는 Leaflet 이 이벤트를 받고 maplibre 가 뒤따라 그리는 구조라 드래그가 한 박자 늦다.
- 전송량은 중간 줌에서 래스터와 비슷하고(시·도 단위 한 화면 약 370KB), 동네 단위(z14)에서 무거워진다(서울 한 화면 약 1.5MB). 대신 그 이상 확대해도 추가 다운로드가 없고 선명하다.

## 실무 지침

- 제품 **기본값은 키·계정이 필요 없는 제공처**로 두고, 배포처가 갈아끼울 수 있게 타일 주소를 런타임 설정으로 노출한다. → [[knowledge/patterns/runtime-config-via-server-route]]
- 제공처가 보유하지 않은 줌을 요청하면 빈 타일이나 안내 이미지가 온다. Leaflet 은 `maxNativeZoom` 으로 상한을 주면 그 줌 타일을 확대해 그린다(`_clampZoom` → `_setZoomTransform`).
- 배경과 지명이 분리된 타일(Esri 회색 캔버스 등)은 라벨 레이어를 배경 위·데이터 아래 pane 에 올린다. 데이터 마커를 가리지 않게 `pointer-events: none` 을 준다.
- 워터마크·차단 안내는 **그림 안**에 들어오므로 HTTP 200 이다. 상태 코드와 콘솔만 보면 절대 안 보인다.

## 관련 페이지

- [[projects/dna-sql-agent/issues/carto-basemap-api-key-watermark]]
- [[projects/dna-sql-agent/decisions/040-keyless-raster-basemap]]
