---
type: session-log
project: dna-sql-agent
date: 2026-06-26
duration: 
focus: "GeoJSON 지도 시각화 (점/지명 색칠/흐름) + 대시보드 개선"
tools-used: [claude-code]
outcome: success
---

# 2026-06-26 — GeoJSON 지도 시각화 (점·지명 색칠·흐름)

## 목표

위경도·지명·노선(출발→도착) 데이터를 지도로 시각화. visualize 도구에 `chart_type='map'`을 추가하고, 프론트(Leaflet)에서 GeoJSON을 렌더해 채팅·북마크·대시보드에 연동한다.

## 수행한 작업

1. **백엔드 map 차트 추가** (`dna_visualize_data.py`, `geojson_service.py`, `region_boundary.py`)
   - `chart_type='map'` 분기(엔진 무관): **흐름(flow) → 위경도(point) → 지명(choropleth)** 순 판별
   - point: lat/lon → 임베드 GeoJSON 스냅샷 (value=크기, color=범주, label=이름)
   - choropleth: region(지명/국가) → 경계 폴리곤 색칠. 한국 시도·세계 국가 경계 GeoJSON 내장(Douglas-Peucker 단순화), 한글/영문/ISO3 별칭 매칭·레벨 자동판별
   - flow: dep/arr 좌표쌍 → LineString + 허브 점. value=선 굵기, color 미지정 시 출발지 기본
   - GeoJSON 변환 API + bbox 필터·줌 격자 클러스터링(대용량 동적 조회)
   - 컬럼명 **대소문자 무시 매칭**(`_resolve_col`) — LLM이 케이스 틀려도 동작
2. **프론트 지도 렌더러** (`map-block-impl.tsx`, `map-chart-block.tsx` 등)
   - leaflet/react-leaflet 도입. 점(버블)·choropleth(색칠)·flow(흐름선+삼각형 화살촉) 렌더
   - 지명 한글 라벨(polylabel pole-of-inaccessibility, 날짜변경선/구멍 보정), 선택(테두리·핀), 다크모드 색 보정, 심플 기본 배경
   - 좌측 데이터 목록/상세 패널(독립 접기, hover 전체표시, valueField 수치·천단위 포맷), 우측 범례(고정폭·헤더 고정·접기·radius 클립)
   - 차트/지도 팔레트 분리(`map-palette.ts`), 단일색 차트(히트맵·scatter) 메인색
   - 채팅(chart_map 스텝)·북마크·대시보드 위젯 연동, 샘플 페이지(`/map-sample`)
3. **대시보드 개선/버그 수정**
   - 위젯 헤더/푸터 숨김 → absolute 오버레이(차트 확대 + hover 표시), 맵 z-index `isolate` 격리
   - 삭제 시 setState-in-render, 전체 새로고침 일부만 되던 문제, 위젯 추가 패널 button 중첩 수정
   - **북마크/위젯 새로고침 시 지도 타입 보존** (`render_bookmark`에 map 분기)
4. **PR 생성**: 백엔드 #81, 웹 #60 (개요/변경/테스트 형식, 작성자 표시 없이)
5. 범례 선택 사용자별 저장 기능은 착수했다가 **요청으로 원복**(부가 기능)

## 핵심 결정

- **지도 payload는 임베드 스냅샷**(다른 차트처럼) + bbox API는 대용량 옵션
  → ADR: [[decisions/018-geojson-map-visualization]]
- **label/color는 LLM이 선정**(x/y처럼) — 프론트/서버 휴리스틱 제거. 흐름 color는 의미 있는 범주 고르되 없으면 출발지 폴백(방향 플래그 같은 행 단위 값 지양)
- choropleth는 한국 시도→세계 국가로 피벗(국가별 매출 비교 데이터 대응)

## 배운 것

- react-leaflet `<Tooltip>`/레이어는 부모 `<Pane>`의 pane 컨텍스트를 상속 → 명시 pane 지정 필요
- Leaflet 벡터 클릭 포커스 네모는 `.leaflet-interactive` outline 제거로 처리
- 가상스크롤 + 비동기 높이(맵 lazy) 요소는 ready/zoom 시 리렌더 유발 필요(MapTicker)
- 맵의 높은 z-index가 카드 헤더/푸터를 덮음 → 차트 영역 `isolate`로 stacking context 격리

## 문제 & 해결

- **문제:** 대시보드 위젯 새로고침 시 지도가 바 차트로 바뀜
- **원인:** `render_bookmark`에 map 분기가 없어 echarts/plotly로 재생성
- **해결:** map 분기 + map 인자(lat/lon/region/dep·arr) 전달 추가
  → 이슈: [[issues/bookmark-refresh-map-type-lost]]

- **문제:** 대시보드 삭제 시 "Cannot update Router while rendering" + 전체 새로고침 일부만
- **원인:** setDashboards updater 안에서 router.push(부수효과) / stale closure로 마지막 결과만 반영
- **해결:** 부수효과를 updater 밖으로, 새로고침 결과를 모아 한 번에 반영
  → 이슈: [[issues/dashboard-delete-setstate-in-render]]

## 다음 할 일

- [ ] PR #81(백엔드)·#60(웹) 리뷰·머지
- [ ] 백엔드 재시작 후 지도 3형태·새로고침 동작 확인
- [ ] (보류) 대시보드 범례 선택 사용자별 저장 — view_state JSONB 컬럼 방식 검토만 함

## 효과적이었던 프롬프트

```
(payload 검증) python -c "...dataframe_to_flow_payload(...); print(field_mapping, props, match)"
— 백엔드 변환 결과를 즉석 실행해 키 일치/구조를 확인
```
