---
type: session-log
project: dna-sql-agent
date: 2026-06-15
duration: ~6h
focus: "북마크 기반 대시보드 기능 — 백엔드 + 프론트엔드 전체 구현"
tools-used: [claude-code]
outcome: in-progress
---

# 2026-06-15 — 북마크 기반 대시보드 기능 구현

## 목표

1. 북마크된 차트 카드를 대시보드 위젯으로 배치하는 기능 구현
2. 드래그앤드롭으로 레이아웃 자유롭게 구성 (react-grid-layout)
3. 위젯은 저장된 SQL을 재실행하여 실시간 데이터 반영

## 수행한 작업

### 백엔드

1. **DB 스키마 추가** (`src/dna/database/schema.py`)
   - `bookmarks` 테이블에 `query_sql`, `connection_name`, `system_name`, `chart_config` 컬럼 추가
   - `dashboards` 테이블 신규 생성 (user_id FK, title, description)
   - `dashboard_widgets` 테이블 신규 생성 (dashboard_id FK, bookmark_id FK, pos_x/y, width/height, cached_chart_data)

2. **Bookmark 확장** (`src/dna/bookmarks/`)
   - `BookmarkResponse`에 4개 필드 추가 (query_sql, connection_name, system_name, chart_config)
   - `_extract_query_info()` 헬퍼 함수: 북마크 생성 시 `messages.tool_calls`에서 SQL 자동 추출
     - `visualize_data.arguments.filename` → `ChartComponent.config.source_file` 매칭으로 chart_config 추출
     - `run_sql` tool_results.content의 CSV 파일명 매칭으로 query_sql 추출
     - 실패 시 fallback: 대화 내 마지막 run_sql SQL 사용
   - `POST /bookmarks/{id}/render` 엔드포인트 추가: SQL 재실행 → 차트 재렌더 → cached_chart_data 업데이트

3. **Dashboard 모듈 신규** (`src/dna/dashboards/`)
   - models.py: DashboardResponse, WidgetResponse, DashboardDetailResponse 등 8개 모델
   - routes.py: 8개 엔드포인트 (CRUD + 위젯 추가/삭제/레이아웃 저장)

4. **테스트** (`tests/`)
   - `test_bookmarks.py`: 2개 기존 테스트 수정 (fake 데이터에 신규 컬럼 추가, tool_calls mock 추가)
   - `test_dashboards.py`: 신규 20개 테스트 작성

5. **문서** (`docs/`)
   - `bookmark-design.md` 업데이트
   - `dashboard-design.md` 신규 작성

### 프론트엔드 (dna-sql-agent-web)

1. **설계 문서** (`docs/dashboard-design.md`)
   - split-panel 레이아웃으로 전면 재설계 (ConversationList + DashboardView 동시 표시)

2. **의존성 추가**: `react-grid-layout`, `@types/react-grid-layout`

3. **타입 추가** (`lib/types.ts`): Dashboard, DashboardWidget, DashboardDetail, BookmarkRenderResult

4. **API 클라이언트** (`lib/dashboard-api.ts`): 8개 API 함수

5. **컴포넌트 신규**
   - `dashboard-widget.tsx`: 위젯 카드 (차트 렌더 + 개별 새로고침)
   - `widget-add-panel.tsx`: 북마크 검색 및 위젯 추가 패널
   - `dashboard-detail.tsx`: 오른쪽 패널 (react-grid-layout 드래그앤드롭, 편집/보기 모드)
   - `dashboard-panel.tsx`: 왼쪽 패널 (대시보드 목록, CRUD 다이얼로그)
   - `dashboard-view.tsx`: split-panel 루트 컴포넌트

6. **기존 수정**
   - `conversation-list.tsx`: 대시보드 버튼 추가 (LayoutGrid 아이콘)
   - `app/(app)/layout.tsx`: isDashboard 분기 + DashboardView 연결 + handleOpenDashboard 핸들러

7. **라우트**: `/dashboard`, `/dashboard/[id]` 페이지 추가

## 핵심 결정

- **결정 1:** 북마크 생성 시 SQL을 사전 추출 (사이드카 파일 방식 대신)
  → ADR: [[decisions/015-bookmark-sql-extraction]]
- **결정 2:** 위젯 초기 로드는 스냅샷, 새로고침 시에만 SQL 재실행 (성능 최적화)
  → ADR: [[decisions/015-bookmark-sql-extraction]] (캐시 전략 포함)
- **결정 3:** Split-panel 레이아웃 (목록 + 상세 동시 표시) — 채팅 레이아웃과 동일한 UX 패턴

## 배운 것

- `react-grid-layout`은 `export =` CommonJS 형식이라 `import { Layout }` 불가 → 로컬 인터페이스로 대체
- `overflow-hidden` 이 있는 부모 컨테이너는 자식 패널의 pointer events를 실제로 차단하지 않지만, 자식 패널이 렌더 영역 밖으로 밀리면 보이지만 클릭 안 되는 증상이 발생할 수 있음
- React 19 타입에서 컴포넌트 props에 `children`이 암묵적으로 포함 안 됨 → `require()` 캐스팅으로 우회

## 문제 & 해결

- **문제:** `widget-add-panel`에서 북마크 목록이 보이지만 클릭이 안 됨
- **원인:** 1) 아이템 전체 div에 onClick 없이 작은 + 버튼만 클릭 가능, 2) `overflow-hidden` 부모가 패널의 포인터 이벤트 영역을 제한할 가능성
- **해결:** 아이템 div에 onClick 추가, ScrollArea를 네이티브 `overflow-y-auto` div로 교체, 패널에 `z-10 relative` 추가, 부모 컨테이너 `overflow-hidden` 제거
  → 이슈: [[issues/widget-add-panel-click-not-working]]

- **문제:** `test_bookmarks.py` 기존 테스트 2개 실패
- **원인:** fake mock 데이터에 신규 DB 컬럼이 없어 KeyError, assert dataframe not in 로직 반전
- **해결:** mock 데이터 업데이트, tool_calls fetch mock 추가

## 다음 할 일

- [ ] 위젯 추가 클릭 버그 실제 화면에서 재확인 (수정 완료 후)
- [ ] 기존 북마크에 query_sql 없는 경우 사용자 안내 메시지 개선 (⚠️ 표시)
- [ ] DashboardView 전체 새로고침 버튼 UX 개선
- [ ] 백엔드 `feat/dashboard` 브랜치 PR 생성 및 머지
- [ ] 프론트엔드 `feat/dashboard` 브랜치 PR 생성 및 머지
