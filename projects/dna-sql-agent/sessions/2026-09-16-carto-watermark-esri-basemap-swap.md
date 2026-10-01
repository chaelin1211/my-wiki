---
type: session-log
project: dna-sql-agent
date: 2026-09-16
duration:
focus: "지도 배경 CARTO 워터마크 원인 규명 + 키 없는 Esri 타일로 교체"
tools-used: [claude-code, claude-in-chrome]
outcome: success
---

# 2026-09-16 — 지도 "API KEY REQUIRED" 워터마크 대응

## 목표

지도에 `API KEY REQUIRED` 가 뜨는 원인을 찾고 없앤다. 최초 의심은 "환경변수를 추가해서 생긴 문제" 였다.

## 수행한 작업

1. 환경변수 가설 검증 — 웹 리포·배포 패키지·실행 중 프로세스 어디에도 `MAP_TILE_*` 이 설정돼 있지 않음을 확인. 가설 기각.
2. 타일을 직접 내려받아 이미지를 열어봄 — CARTO `light_all` PNG 안에 `API KEY REQUIRED / carto.com/basemaps` 가 대각선으로 인쇄돼 있었다. 제공처 정책 변경이 원인.
3. 대안 조사 — Esri 회색 캔버스(래스터), OpenFreeMap(OpenMapTiles 벡터), CARTO 키 발급 세 가지를 수치로 비교. → ADR-040
4. Esri 타일의 줌별 커버리지 측정 — 한국은 밝은 배경 z13, 어두운 배경 z16 까지만 데이터가 있고 그 위는 "Map data not yet available" 이미지가 내려온다.
5. 구현 — `lib/map-themes.ts` 기본값 교체(`labelUrl`·`maxNativeZoom` 필드 추가), `map-block-impl.tsx` 에 라벨 타일 레이어 추가(`map-labels` pane, z-index 250, 클릭 통과).
6. 검증 — 빌드·타입 확인, `/map-config` env 조합 4가지 응답 확인, 브라우저로 어두운 테마 실화면 확인.
7. PR #90 (dna-sql-agent-web) 생성, 커밋 3개.

## 핵심 결정

- **결정 1:** 기본 배경을 키 없는 Esri 회색 캔버스(래스터)로 교체. 벡터(OpenFreeMap)와 CARTO 키 발급은 제외.
  → ADR: [[decisions/040-keyless-raster-basemap]]
- **결정 2:** 출처 문구는 제공처 두 곳 링크로 축약(`© Esri | © OpenStreetMap`). 원문 전체는 우측 하단 모드 토글과 겹칠 만큼 길다.

## 배운 것

- 무료 타일 제공처는 **코드를 건드리지 않아도 어느 날 화면이 깨질 수 있다.** 워터마크가 타일 이미지 안에 인쇄돼 오면 HTTP 는 200 이라 에러 로그에도 안 남는다. 증상이 "그림 안" 에 있으면 타일을 받아서 눈으로 열어보는 게 가장 빠르다.
- Esri 회색 캔버스는 **지역마다 타일 보유 줌이 다르다.** 한국은 밝은 배경이 z13 까지뿐인데 뉴욕은 z16 까지 있다. Leaflet `maxNativeZoom` 으로 상한을 주면 그 줌 타일을 늘려 그려서 "데이터 없음" 이미지를 피한다.
- OSM 공식 타일은 `Referer` 없이 요청하면 403 `Access blocked` 를 그림으로 돌려준다. curl 로만 확인하면 서비스 장애로 오해하기 쉽다. 브라우저는 `Referer` 를 보내므로 실제로는 정상이다.
- 래스터/벡터 차이가 곧 작업량 차이다. 벡터 전용 제공처를 쓰려면 Leaflet 만으로는 못 그리고 maplibre 엔진(gzip 293KB)과 WebGL 의존이 따라온다.

## 문제 & 해결

- **문제:** 지도 배경에 `API KEY REQUIRED` 워터마크.
- **원인:** CARTO 가 무료 베이스맵 타일에 워터마크를 넣기 시작. 심플 모드(기본 화면)의 기본 타일이 CARTO 였다.
- **해결:** 기본값을 Esri 회색 캔버스 + 라벨 레이어로 교체하고 줌 상한 지정.
  → 이슈: [[issues/carto-basemap-api-key-watermark]]

## 다음 할 일

- [ ] PR #90 머지 후 `dna-sql-agent-web_dev.yml` 수동 실행(workflow_dispatch)으로 dev 반영
- [ ] linko·mobigen 워크플로도 각각 실행, 설치 패키지 고객사는 이미지 재배포
- [ ] 밝은 테마 z13 이상 화면·기본 모드 전환을 육안 확인 (브라우저 자동화 3회 실패로 미확인)
- [ ] CI 워크플로 3개에 env/시크릿 주입 지점이 전혀 없는 점 검토 — 지금은 `.env.production` 만이 통로

## 효과적이었던 프롬프트

```
그냥 api key 등록하면 되는 거 아냐?
```

가장 단순한 대안을 되물어 선택지를 강제로 재검토하게 만들었다. 덕분에 "상업적 사용은 엔터프라이즈 라이선스 논의 대상" 이라는 조건과 "키가 브라우저에 노출된다" 는 제약을 확인하고 기록에 남길 수 있었다.
