---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-26
resolved: true
root-cause: "render_bookmark에 map 분기 부재 → echarts/plotly로 재생성"
related: [018-geojson-map-visualization]
tags: [dashboard, bookmark, map, visualization]
---

# 대시보드 위젯/북마크 새로고침 시 지도가 바 차트로 바뀜

## 증상

지도(map) 위젯을 새로고침(또는 page reload 후 캐시 사용)하면 지도가 사라지고 바 차트로 표시됨.

## 환경

- **재현 조건:** 지도 위젯이 있는 대시보드에서 새로고침(`renderBookmark`) 또는 캐시된 chart_data 사용

## 시도한 것들

1. ❌ 프론트 ChartPreview 분기(geojson/chart_type/option) 점검 — 분기는 정상, componentData.data도 판별자 보유
2. ✅ 백엔드 `render_bookmark` 추적 — map 처리가 아예 없음

## 근본 원인

`bookmarks/routes.py:render_bookmark`는 SQL 재실행 후 `_generate_echarts`/`_generate_with_hints`로만 차트를 재생성했다. `chart_type='map'`이어도 map 분기(`_build_map_payload`)가 없고 lat/lon/region/dep·arr 인자도 ArgsSchema에 전달되지 않아, 일반 차트(바)가 생성·캐시됨. (map 분기는 `execute()`에만 존재)

## 해결 방법

`render_bookmark`에 map 분기 추가:
- ArgsSchema에 map 인자(lat/lon/region/dep_lat/dep_lon/arr_lat/arr_lon/from_label/to_label) 전달 — 값은 `chart_config`(visualize 호출 args 전체)에 이미 저장됨
- `if args.chart_type == 'map': chart_data = viz_tool._build_map_payload(df, args, title)` — 전처리 이전에 분기(execute와 동일)

## 교훈

- 같은 시각화를 **재생성하는 경로가 둘 이상**이면(실행 시 vs 새로고침) 차트 타입 분기 로직을 공유하거나 양쪽에 동일하게 둬야 함. map 같은 신규 타입 추가 시 재렌더 경로 점검 필수.
- 이미 잘못 캐시된 위젯은 백엔드 재시작 후 한 번 새로고침해야 정정됨(`cached_chart_data` 우선).
