---
type: project-status
project: dna-sql-agent
updated: 2026-06-26
phase: active
---

# dna-sql-agent — 현재 상태

## 현재 단계

🔧 **초기 설정** 단계

## 완료된 것

- [x] 위키 프로젝트 폴더 생성
- [x] 계정 별 채팅 히스토리 유지를 위한 API, DB 설계 및 개발
- [x] LLM Context 유지 정책 스터디 및 장기 대화 요약 기능 구현
- [x] 계정 별 채팅 히스토리 유지 및 Context 유지를 위한 요약 기능 문서화
- [x] UI 작업 요소들 리스트업 (시각화 툴 수정 - chart 종류 추가 및 종류 선택 llm에게 일임)
- [x] few-shot 활용 전략 확정 — 비즈니스 로직/도메인 지식 제공용 (document RAG 구축 대신)
- [x] UI 개선 목표 방향 확정 — 오류 없이 동작, 한글화 우선(i18n 미적용), 관리자 페이지 포함
- [x] 웹 서버 배포
- [x] 서비스 명 확정 — 다답
- [x] 요구사항 담당자 할당 관련 검토
- [x] 브랜치 생성 — main / mania (백업·배포용) 분리
- [x] 진행사항 관리 방식 확정 — 시트 내 관리 (완료 여부, 완료 일자, 완료율)
- [x] bug fix: 시스템 비활성화 시 404 오류 (get_system_by_conn_and_name status 필터 문제)
- [x] bug fix: 채팅 생성 시 쿼리 수정 (시스템 조회 시 커넥션 매핑 확인)
- [x] bug fix: inactive 커넥션 목록 표시 및 채팅 필터 처리
- [x] bug fix: 대화 저장 시 tool 미사용·텍스트만 오는 경우 저장 안 되는 버그 (web 필터링)
- [x] feat: PATCH /api/v1/chat/{conversation_id}/title 대화 제목 수정 API 추가
- [x] test: JWT auth, chat history 단위 테스트 추가 (9건)
- [x] feat: 채팅 목록 상단 고정(pin) 기능 — PATCH /api/v1/chat/{id}/pin
- [x] feat: 채팅 결과 카드 즐겨찾기(bookmark) 기능 — /api/v1/bookmarks CRUD
- [x] feat: BookmarkResponse에 component_created_at 추가, 생성일 정렬 기준 변경
- [x] feat: SSE 종료 이벤트 → `{"type":"done","message_id":...}` (북마크 신규 메시지 404 해결)
- [x] fix: DevExtreme 차트 E2004 — 컬럼명 대소문자 무시 매칭 + auto-select fallback
- [x] 연관관계 추론 방식 확정 — 벡터라이징 시점에 수행, 쿼리 생성 시 추론 결과 포함하여 전달
- [x] 대화 목록 description — 마지막 메시지 조회 후 표시하도록 수정
- [x] bookmark PR #25 머지
- [x] PR #27 리뷰 및 머지 (fix/chat-bookmark — message_id SSE 전달, E2004 수정)
- [x] 프론트엔드 SSE done 이벤트 수신 및 북마크 연동 (type:"done" → message_id 활용)
- [x] 채팅 목록 제목 정책 수립 및 반영 (현재는 첫번째 user message)
- [x] 화면 - 채팅 목록 채팅 제목 밑에 No message 확인 및 처리
- [x] 요구사항 정리 문서 작성 및 담당자 배정
- [x] PR #28 머지 (feat/chat-list-description — last_message 필드 추가, 2026-05-26)
- [x] feat: refresh token 도입 — access token 30분, refresh token 7일, POST /auth/refresh·/auth/logout 추가
- [x] 프론트엔드 refresh token 연동 (401 인터셉터, 토큰 갱신 큐잉, 로그아웃 API 호출) — PR #33 생성 (2026-05-27)
- [x] feat: 시스템 권한 일괄 부여/회수 API — POST/DELETE /admin/systems/{system_id}/users/bulk (2026-05-29)
- [x] feat: TokenResponse에 expires_in 추가 — 프론트 refresh 타이밍 문제 근본 해결 (2026-05-29)
- [x] fix: CORS에서 개인 IP 제거 (2026-05-29)
- [x] fix: sql_examples type 컬럼 반영 — 화면 입력(M)/자동 수집(A) 구분 (2026-06-01)
- [x] PR #38 생성 (feat/admin-improvements — bulk 권한 API, expires_in, type 컬럼)
- [x] feat: ECharts 차트 엔진 추가 — EChartsChartGenerator, 동적 스키마, sankey 등 (2026-06-02)
- [x] PR #39 생성 (feat/echarts-engine)
- [x] refactor: ECharts scatter/bubble 개선 — visualMap 버블 크기, 툴팁 pre-line 방식 (2026-06-05)
- [x] refactor: 프론트/백 레이아웃 책임 분리 — color palette, confine, grid 프론트 전담 (2026-06-05)
- [x] fix: Sankey DAG 사이클 링크 iterative DFS 제거 (2026-06-05)
- [x] fix: DevExtreme bubble 지원, _label inf 처리, DX bubble x numeric 강제 (2026-06-05)
- [x] docs: echarts-chart-design.md 섹션 11 추가 (구현 후 개선사항) (2026-06-05)
- [x] feat: ECharts scatter label 파라미터 추가 (per-item 텍스트 라벨) (2026-06-08)
- [x] feat: ECharts combo 차트 추가 (bar+line 이중 y축) (2026-06-08)
- [x] fix: Sankey Oracle Decimal 티어 컬럼 오감지 (coerce_numeric=False) (2026-06-08)
- [x] fix: Sankey BFS 중복 큐 → Kahn's topological sort 교체 (2026-06-08)
- [x] refactor: 시스템 프롬프트 압축 및 섹션 헤더 영어 통일 (2026-06-08)
- [x] PR #45 생성 (refactor/chart-visualization) (2026-06-08)
- [x] refactor: 동기 블로킹 호출 asyncio.to_thread() 래핑 (embedding, Qdrant, psycopg2, oracledb) (2026-06-09)
- [x] feat: 스트리밍 중단 시 사용자 메시지 DB 저장 — try/finally + stream_completed 패턴 (2026-06-09)
- [x] feat: 사이드바 스트리밍 배지 — bg-primary 색상, 타이틀 앞 위치 (2026-06-09)

## 완료된 것 (2026-06-10 추가)

- [x] feat: group_table_permissions 테이블 추가 — 그룹 × 시스템 단위 차단/쓰기허용 테이블 관리 (2026-06-10)
- [x] feat: GET/PUT /admin/groups/{group_id}/table-permissions API 추가 (2026-06-10)
- [x] refactor: SQL Guard auth → DB 기반 async 조회 전환 (sql_guard.json 폐기) (2026-06-10)
- [x] feat: SQL Guard schema.table 형식 차단 지원 — 스키마별 동명 테이블 구분 (2026-06-10)
- [x] fix: 가드레일 차단 시 LLM 재시도 우회 방지 — result_for_llm에 재시도 금지 지시 (2026-06-10)
- [x] feat: SQL 실행 쿼리 INFO 로그 추가, 차단 시 BLOCKED WARNING 로그 (2026-06-10)
- [x] feat: group_permissions, group_masking_actions 테이블 추가 — 그룹 권한 DB 통합 (2026-06-10)
- [x] feat: group-permissions API (tool/ui_feature/masking) 추가 (2026-06-10)
- [x] refactor: masking.json groups 필드 제거 — 그룹 액션 DB로 완전 이관 (2026-06-10)
- [x] feat: SecurityTab 마스킹 그룹 처리 방식 → DB 기반 전환 및 SaveBanner 연동 (2026-06-10)

## 완료된 것 (2026-06-11 추가)

- [x] refactor: tool_access.json에서 access_groups 제거 — DB 단일 진실 공급원 원칙 일관 적용 (ADR-013) (2026-06-11)
- [x] feat: ValidatedRunSqlTool always_enabled 플래그 도입 — 핵심 도구 비활성화 방지 (ADR-014) (2026-06-11)
- [x] fix: SQL 가드레일 차단 메시지 정제 — 재시도 금지 절대 명령 제거, 우회 금지만 유지 (2026-06-11)
- [x] feat: 시스템 프롬프트에 현재 차단 테이블 목록 실시간 주입 (DnaSystemPromptBuilder) (2026-06-11)

## 완료된 것 (2026-06-12 추가)

- [x] fix: hot-reload 시 신규 그룹 기본 마스킹 초기화 버그 — get_default() → load() (2026-06-12)
- [x] feat: 테이블 접근제어 그룹/시스템 전환 시 변경사항 누적 후 한 번에 저장 (pendingChanges 맵) (2026-06-12)
- [x] fix: 테이블 접근제어 선택 전환 시 깜빡임/꿀렁임 제거 (2026-06-12)
- [x] PR #50 생성 (refactor/admin-page), PR #42 생성 (feat/group-table-permissions) (2026-06-12)

## 완료된 것 (2026-06-15 추가)

- [x] feat: 북마크 SQL 자동 추출 — messages.tool_calls 파싱으로 query_sql, chart_config 저장 (ADR-015) (2026-06-15)
- [x] feat: POST /bookmarks/{id}/render — SQL 재실행 + 차트 재렌더 + cached_chart_data 캐싱 (2026-06-15)
- [x] feat: dashboards 테이블 + dashboard_widgets 테이블 신규 생성 (2026-06-15)
- [x] feat: Dashboard CRUD + 위젯 추가/삭제/레이아웃 저장 API 8개 (2026-06-15)
- [x] test: test_dashboards.py 20개 테스트 신규 작성 (2026-06-15)
- [x] feat: 프론트엔드 대시보드 split-panel 레이아웃 (react-grid-layout 드래그앤드롭) (2026-06-15)
- [x] fix: widget-add-panel 클릭 불동 — div onClick, ScrollArea 제거, z-10 추가 (2026-06-15)

## 완료된 것 (2026-06-15 추가 — 대시보드 크기 모델)

- [x] feat: 위젯 크기 프리셋 2종(최소 1칸×4행 / 최대 2칸×콘텐츠 높이 스냅), 자유 리사이즈 폐기 (ADR-016) (2026-06-15)
- [x] feat: 반응형 컬럼(colsForWidth 1200/700 → 4/2/1열), 너비 단위 1칸 (2026-06-15)
- [x] feat: 비례 높이(rowHeight = clamp(colWidth×0.18, 40, 130)) — 폭 따라 위젯 비율 유지 (2026-06-15)
- [x] feat: 드래그 격자 스냅(RGL v2 constraints: snapToGrid + gridBounds, /core 서브패스) (2026-06-15)
- [x] fix: 편집 모드 4열 고정 — 좁은 폭 저장 시 배치 손실 방지 (캐노니컬 좌표 유지) (2026-06-15)
- [x] fix: 위젯 헤더 고정 37px + 카드 border 반영(WIDGET_CHROME=84)으로 차트 하단 여백 짤림 해결 (2026-06-15)
- [x] feat: 위젯 푸터 출처 대화 링크 — WidgetResponse conversation_id/title 조인 + onNavigateToConversation 배선 (2026-06-15)
- [x] refactor: 높이/크기 계산 lib/chart-height.ts로 일원화, echarts 콘텐츠 높이 로직 추출 (2026-06-15)
- [x] docs: 대시보드 설계서 갱신 — 웹 8장 v2/크기 모델 전면, 백엔드 WidgetResponse 대화 필드 (2026-06-15)

## 완료된 것 (2026-06-16 추가)

- [x] fix: 로그아웃 후 재로그인 시 이전 계정 대화 목록 표시 — useConversations 독립 useAuth() 인스턴스 제거, AppProvider에서 주입 (2026-06-16)

## 완료된 것 (2026-06-17 추가)

- [x] feat: nginx HTTP 28001 포트 추가 — PPT 애드인 webview HTTP 접근 지원 (ADR-015) (2026-06-17)
- [x] refactor: Next.js 컨테이너 포트 28001 → 3000 변경 (nginx가 28001 소유) (2026-06-17)
- [x] refactor: 백엔드/웹 워크플로우 전체 --network host 통일 (Docker 커스텀 네트워크 방식 서버 방화벽으로 포기) (2026-06-17)
- [x] feat: 위젯 추가 패널 이미 추가된 위젯 hover → X 표시 & 클릭 제거 (destructive 스타일) (2026-06-17)
- [x] feat: 스크롤 그림자 — widget-add-panel, dashboard 그리드, bookmark-view 세 곳 (다크모드 opacity 완화) (2026-06-17)
- [x] feat: 새로고침 버튼 툴팁에 정확한 로드 시각 표시 (2026-06-17)
- [x] feat: bookmark/dashboard widget API 응답에 system_display_name 포함 — 프론트 별도 getSystems 조회 제거 (2026-06-17)
- [x] feat: PPT 애드인 환경에서 대시보드 버튼 숨김 (2026-06-17)
- [x] fix: git filter-branch로 실수 커밋 파일 제거 및 부작용으로 삭제된 파일 복원 (2026-06-17)

## 완료된 것 (2026-06-23 추가)

- [x] fix: run_sql LIMIT 자동 주입 시 LLM·UI 고지 — 실행 SQL 로그 표시 + result_for_llm 앞에 LIMIT 고지 prepend (시각화 제목 전수 조회 표현 방지) (2026-06-23)
- [x] fix: 북마크 query_sql에 LIMIT 반영 — create_bookmark 저장 시 _inject_limit 적용, 대시보드 새로고침 전체 조회 부하 해결 (2026-06-23)
- [x] feat: DataTable 컬럼 헤더 클릭 정렬 (숫자·문자 자동 판별) (2026-06-23)
- [x] fix: DataTable sticky 헤더 — shadcn Table overflow 래퍼 문제로 plain table 교체, bg-muted 불투명 배경 (2026-06-23)
- [x] fix: 채팅 table 시각화 높이 개선 (non-flat chartHeight 전달), 북마크 확장/일반 높이 정합, 10행 제한 해제 (2026-06-23)
- [x] PR #77 생성 (백엔드 — LIMIT 고지·북마크 반영), PR #56 생성 (프론트 — DataTable 정렬·sticky·높이) (2026-06-23)

## 완료된 것 (2026-06-25 추가)

- [x] feat: (#68) 시스템 제외 테이블을 실제 테이블 목록 조회·선택 방식으로 — GET /connections/{id}/tables API + 트랜스퍼 리스트/태그+(+)펼침 UI (2026-06-25)
- [x] feat: 시스템 스키마 입력을 detect-schemas 기반 드롭다운 체크박스 멀티셀렉트로 교체 (대소문자 무시 매칭·케이스 정규화·직접입력 fallback) (2026-06-25)
- [x] fix: detect_schemas 조회 범위 확대(all_tables/pg_tables) — list_tables와 동일 소스로 누락 스키마 해결 (2026-06-25)
- [x] feat: 보안>테이블 접근 제어(차단/쓰기허용)도 동일 테이블 목록 선택 방식 적용 (재사용 컴포넌트 table-transfer-select) (2026-06-25)
- [x] feat: DB 연결에 version 컬럼 + 연결 테스트 자동 감지, 시스템 프롬프트에 DB 메타(종류·버전) 주입 (2026-06-25)
- [x] feat: 권한용 available-systems 응답에 connection_id·schemas 추가 + 정렬 시스템 관리와 통일 (2026-06-25)
- [x] fix: 설정 리셋이 마지막 저장값으로 복원되도록 수정 + 테이블접근제어/인프라 권한 reset 미배선 버그 (2026-06-25)
- [x] feat: LLM 연결 활성화 즉시 저장 통일 (ADR-017), foundation 탭 SaveBanner→안내문구 (2026-06-25)
- [x] style: 설정 토스트 공통화·한글화, 아이콘 버튼 호버 색 통일(.icon-btn), 영어 UI 문구 한글화 (2026-06-25)
- [x] PR 생성: 백엔드 feat/connection-version (Closes #68), 프론트 feat/system (2026-06-25)

## 진행 중
- [ ] SQL Guard: 대화 히스토리 내 차단 테이블 결과 잔류 — 권한 변경 시 이전 대화 비활성화 방식 추가 검토 (보류)
- [ ] SQL Guard: RAG 테이블 추출 시 프롬프트에 테이블 제약 포함 (top 테이블 사전 필터링)
- [x] 데이터 위경도 정보 GeoJson 표출 기능 설계 (참고: eCharts 한국 최신 데이터)

## 다음 할 일
- [ ] 벡터 검색 정확도 개선 — 예상 질문을 컬럼별 아닌 관계(relation) 기준으로 재생성
- [ ] 테이블 선정 근거 로그 표시 화면 추가 검토
- [ ] 자동 벡터화 수정 화면 필요 여부 결정 (Qdrant 직접 수정 vs 별도 화면)
- [ ] office.js 기반 PPT 추가기능 개발 방안 검토
- [ ] 네트워크 공유 기반 추가기능 배포 방식 확인
- [ ] 슬라이드 삽입 요청 처리 흐름 구체화 (tool 호출 → 화면 감지 → 삽입)
- [ ] 발표 일정 확정 — 우선순위 1순위 수정·테스트 완료 후 fix (2026-05-25 주간 예정)
- [ ] 벡터라이즈 시 모델 재로딩으로 인한 API Hang 수정
- [ ] SQL reverse engineering: admin example 등록 화면에 수집 UI 추가
- [ ] SQL reverse engineering: 백엔드 자동 수집 로직 추가
- [ ] admin example 화면 vectorize 버튼 제거
- [ ] admin 수정 즉시 반영 항목 검토 및 처리

## 2026-06-26 — GeoJSON 지도 시각화

- [x] feat: visualize 도구 `chart_type='map'` 추가 — 점(point)/지명(choropleth)/흐름(flow) 3형태
- [x] feat: GeoJSON 변환 서비스 + bbox 필터·줌 격자 클러스터링 API
- [x] feat: 경계 데이터/지명 매칭 모듈(한국 시도·세계 국가, 한글/영문/ISO3 별칭·레벨 자동판별)
- [x] feat: 프론트 지도 렌더러(leaflet) — 점·choropleth·흐름선(화살촉), 한글 라벨(polylabel)
- [x] feat: 좌측 데이터 목록/상세 패널, 우측 범례(고정폭·접기), 다크모드 색 보정, 팔레트 분리
- [x] feat: 채팅(chart_map)·북마크·대시보드 위젯 연동 + 샘플 페이지(/map-sample)
- [x] feat: 위젯 헤더/푸터 숨김 시 차트 확대 + hover 오버레이(맵 z-index isolate)
- [x] fix: 북마크/위젯 새로고침 시 지도 타입 보존 (render_bookmark map 분기) → [[issues/bookmark-refresh-map-type-lost]]
- [x] fix: 대시보드 삭제 setState-in-render + 전체 새로고침 일부만 → [[issues/dashboard-delete-setstate-in-render]]
- [x] fix: 위젯 추가 패널 button 중첩 hydration, 지도 컬럼명 대소문자 무시 매칭
- [x] PR 생성 — 백엔드 #81, 웹 #60
- [x] ADR: [[decisions/018-geojson-map-visualization]]
- [ ] PR #81·#60 리뷰·머지, 백엔드 재시작 후 동작 확인
- [ ] (보류) 대시보드 범례 선택 사용자별 저장 — view_state JSONB 방식 검토만(원복)

## 블로커

_(없음)_

## 메모

- 미팅: [[meetings/2026-05-13 SQL Agent 검토 회의 (실장님 제작 버전)|2026-05-13 SQL Agent 검토 회의 (실장님 제작 버전)]]
- 미팅: [[projects/dna-sql-agent/meetings/2026-05-18 활용 방안 및 제품명 결정]]
- 미팅: [[projects/dna-sql-agent/meetings/2026-05-26 벡터 연관관계 추론 및 SQL 리버스 엔지니어링 검토]]
- PPT 추가기능 동작 흐름 (실장님 설명):
  1. LLM에게 비율 상의 PPT 컴포넌트·내용 생성 요청
  2. LLM이 JSON 형식으로 슬라이드 구조 반환
  3. 웹에서 PPT 사이즈 기준으로 정확한 위치 계산 후 렌더링
  4. 스타일 템플릿은 웹 소스에 지정된 템플릿 사용
