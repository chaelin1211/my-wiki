---
type: troubleshooting
project: dna-sql-agent
date: 2026-09-16
resolved: true
root-cause: "CARTO 가 무료 베이스맵 타일 이미지에 API KEY REQUIRED 워터마크를 인쇄해 내려주기 시작"
related: [decisions/040-keyless-raster-basemap, decisions/039-runtime-config-via-server-route]
tags: [map, tiles, third-party, frontend]
---

# 지도 배경에 "API KEY REQUIRED" 워터마크

## 증상

지도 심플 모드(기본 화면) 배경에 `API KEY REQUIRED / carto.com/basemaps` 가 대각선으로 인쇄돼 보인다. 배포를 하지 않았는데도 어느 날부터 나타났고, 콘솔 에러도 네트워크 실패도 없다. 타일 요청은 HTTP 200 이다.

## 환경

- **런타임:** dna-sql-agent-web (Next.js 16, Leaflet 1.9 / react-leaflet 5)
- **관련 패키지:** 없음 (외부 타일 제공처 문제)
- **재현 조건:** 심플 모드에서 CARTO `light_all`·`dark_all` 타일을 키 없이 요청

## 시도한 것들

1. ❌ 환경변수 의심 — `MAP_TILE_URL*`·`NEXT_PUBLIC_MAP_TILE_URL` 을 리포·배포 패키지·실행 프로세스에서 전수 확인했으나 어디에도 설정돼 있지 않았다.
2. ❌ 응답 코드·헤더 확인 — 200 에 `image/png`, 크기도 정상이라 단서가 없다.
3. ✅ **타일을 내려받아 이미지를 직접 열어봄** — 그림 안에 워터마크가 인쇄돼 있었다.

## 근본 원인

CARTO 가 무료 베이스맵 정책을 바꿔, 키 없는 요청에는 워터마크를 넣은 타일을 반환한다. 우리 코드는 그대로인데 제공처가 바뀐 것이라 배포 이력을 따라가면 원인을 못 찾는다. 심플 모드가 지도 기본 모드라 사용자 눈에 바로 띄었고, 기본 모드(OSM)는 원래 정상이었다.

## 해결 방법

기본 타일을 키·계정이 필요 없는 Esri 회색 캔버스로 교체하고, 지명이 별도 레이어인 특성에 맞춰 라벨 타일을 한 장 더 그린다. 지역별 타일 보유 줌 차이는 `maxNativeZoom` 으로 흡수한다.

```ts
// lib/map-themes.ts
light: {
  url: `${ESRI_CANVAS}/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}`,
  labelUrl: `${ESRI_CANVAS}/World_Light_Gray_Reference/MapServer/tile/{z}/{y}/{x}`,
  maxNativeZoom: 13,   // 한국은 z13 까지만 타일이 있다
  attribution: ESRI_ATTRIBUTION,
},
```

라벨은 배경(tilePane 200) 위, 데이터(overlayPane 400~) 아래인 z-index 250 pane 에 `pointer-events: none` 으로 올려 점·선을 가리지 않게 한다.

당장 배포를 막아야 하면 코드 변경 없이 env 로도 우회된다(`MAP_TILE_URL_SIMPLE` 에 다른 타일 주소 지정).

## 예방책

- 외부 무료 타일·CDN 은 **코드 변경 없이 화면이 깨질 수 있는 의존성**이다. 기본값은 키·계정이 필요 없는 제공처로 두고, 배포처가 갈아끼울 수 있는 env 통로를 항상 열어 둔다.
- "그림 안" 증상은 로그·상태 코드로 안 잡힌다. 타일·이미지가 의심되면 받아서 열어보는 것을 1순위로 한다.

## 관련 페이지

- [[knowledge/tools/keyless-map-tile-providers]]
- [[decisions/040-keyless-raster-basemap]]
