---
type: decision-record
project: dna-sql-agent
date: 2026-06-15
status: accepted
superseded-by: ""
tags: [dashboard, bookmark, sql, caching]
---

# ADR-015: 북마크 기반 대시보드 — SQL 추출 시점과 캐시 전략

## 맥락

대시보드 위젯은 북마크된 차트를 표시하되, 실시간 데이터를 반영해야 한다.
문제는 `ChartComponent`가 렌더링된 차트 데이터만 저장하고 원본 SQL은 저장하지 않는다는 점.

## 선택지

### 옵션 A: 도구 파이프라인 수정 — 차트 컴포넌트에 SQL 포함
- **장점:** SQL이 항상 차트와 함께 보장됨
- **단점:** `DnaVisualizeDataTool` 수정, SSE 프로토콜 변경, 대량 스키마 마이그레이션 필요
- **비용/노력:** 높음

### 옵션 B: 북마크 생성 시 `messages.tool_calls`에서 SQL 추출
- **장점:** 파이프라인 수정 없음, 기존 데이터 활용
- **단점:** `source_file` 매칭 실패 시 fallback 필요, 구버전 북마크는 null
- **비용/노력:** 중간

### 옵션 C: 위젯 조회 시마다 실시간 SQL 실행
- **장점:** 항상 최신
- **단점:** 대시보드 로드 시 쿼리 폭발, UX 저하
- **비용/노력:** 낮음 (구현), 높음 (운영)

## 결정

**옵션 B + 캐시 전략을 선택한다.**

- 북마크 생성 시 `_extract_query_info()`로 SQL과 chart_config를 자동 추출하여 저장
- 대시보드 초기 로드: 스냅샷(`messages.components`) 즉시 표시 — SQL 실행 없음
- 새로고침 버튼: `POST /bookmarks/{id}/render` → SQL 재실행 → `dashboard_widgets.cached_chart_data` 캐싱

## 근거

- 파이프라인 수정 없이 기존 `tool_calls` 데이터를 재활용할 수 있음
- 초기 로드 성능 보장 (DB 쿼리 없음)
- 위젯별 독립 새로고침으로 특정 위젯만 갱신 가능
- `query_sql`이 null인 구버전 북마크는 새로고침 버튼 비활성화로 graceful degradation

## 결과

- `bookmarks` 테이블에 `query_sql`, `connection_name`, `system_name`, `chart_config` 컬럼 추가
- `dashboard_widgets` 테이블에 `cached_chart_data`, `cached_at` 컬럼 추가
- 구버전 북마크는 `has_query: false`로 렌더링 전용으로만 사용 가능
- `source_file` 매칭 실패 시 fallback: 대화 내 마지막 `run_sql` SQL 사용

## 참고 자료

- `src/dna/bookmarks/routes.py` — `_extract_query_info()`
- `docs/bookmark-design.md` — 섹션 6 (SQL 자동 추출 메커니즘)
- `docs/dashboard-design.md`
