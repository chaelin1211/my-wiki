---
type: project-status
project: dna-sql-agent
created: 2026-04-20
updated: 2026-09-22
phase: active
---

# dna-sql-agent — 현재 상태

## 현재 단계

🚀 **배포·납품 준비** 단계 — v0.9 그룹 관리자 기능 완료, 고객사 배포 패키지(별도 저장소·Nuitka 컴파일·이미지 전달) 구축 중

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
- [x] office.js 기반 PPT 추가기능 개발 방안 검토 — 서버 데이터 생성 + 프론트 렌더링으로 확정
      (아래 2026-08-03 오피스 기능 고도화 참고)
- [ ] 네트워크 공유 기반 추가기능 배포 방식 확인
- [ ] 슬라이드 삽입 요청 처리 흐름 구체화 (tool 호출 → 화면 감지 → 삽입)
- [ ] 발표 일정 확정 — 우선순위 1순위 수정·테스트 완료 후 fix (2026-05-25 주간 예정)
- [ ] 벡터라이즈 시 모델 재로딩으로 인한 API Hang 수정
- [ ] SQL reverse engineering: admin example 등록 화면에 수집 UI 추가
- [ ] SQL reverse engineering: 백엔드 자동 수집 로직 추가
- [ ] admin example 화면 vectorize 버튼 제거
- [x] admin 수정 즉시 반영 항목 검토 및 처리 — 섹션별 `ApplyMode` 선언 + 미반영 배너
      (아래 2026-08-14 참고)

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
- [x] PR #81·#60 머지 (origin/main 반영 확인)
- [ ] (보류) 대시보드 범례 선택 사용자별 저장 — view_state JSONB 방식 검토만(원복)

## 2026-06-30 — 북마크 표시 누락 + 지도(flow/point) 시각화·목록 개선

- [x] fix: 채팅 북마크 표시 누락 — 대화별 경량 refs 조회 `GET /api/v1/bookmarks/refs` + 진입 시 전체 로드 → [[issues/bookmark-display-missing-on-chat-entry]]
- [x] fix: flow map 범례 누락(회귀) — color가 from_label과 같아 display_cols에서 빠지던 것 보강 → [[issues/flowmap-legend-color-equals-from-label]]
- [x] fix: 점 지도 datetime이 epoch 숫자로 뜨던 것 ISO 직렬화 → [[knowledge/troubleshooting/pandas-to-json-datetime-epoch]]
- [x] fix: 라벨 미지정 점이 '(점)'으로 뜨던 것 — 첫 식별 컬럼 자동 라벨 + 점 폴백 시 from_label 라벨
- [x] feat: 지도 데이터 목록 from/id 그룹핑(접기/펼치기), from==to 기준 분류, 선택 묶음 강조 → [[decisions/019-flowmap-list-grouping]]
- [x] fix: 흐름 화살촉 화면 길이 기준 보정(짧으면 축소/생략) + `_mapPane` 가드로 `_leaflet_pos` 크래시 방지
- [x] feat: 포인트 지도 클러스터링 활성화(mapType==='point'), 높은 줌(maxZoom-2)에서 해제
- [x] feat: 지도 범주 팔레트 5→10색 확장·순서 교차 + 다크모드 전용 비비드 팔레트
- [x] feat: flow 부가 컬럼(시간대·모드 등) 툴팁/상세 표시 + 표시 순서 조회 컬럼 순
- [x] docs: map color/범례 도구 설명 보강(FLOW에 color=category 안내, Avoid ID/code 제거)
- [x] refactor: LIMIT 자동 적용 시 화면 안내 제거(실행·LLM 인지·북마크 저장 유지)
- [x] PR 생성 — 백엔드 #90, 프론트 #64 (브랜치 `refactor/bookmark_map`)
- [x] PR #90·#64 리뷰·머지 확인
- [ ] (별개 조사, 이월) 다중 쿼리 수행 내역이 reload/대화전환 시 사라짐 — components 영속화 경합(SaveComponentsMiddleware ↔ ChatSaveHook), build-steps가 components 컬럼만 의존

## 2026-07-03 — 사이드바/헤더 구조 개편 및 대시보드 안정화

- [x] refactor: 대시보드 화면 사이드바를 대화 목록 자리로 승격 — `ConversationList` ↔ `DashboardPanel` 라우트 기반 교체 → [[decisions/020-context-sensitive-sidebar-swap]]
- [x] feat: 공용 `SidebarTopbar`(로고·버전·연결 상태·다크모드 토글·접기), `SidebarUserMenu`(관리자 링크+프로필 팝업) 신설, 전역 `MainHeader`/`AppHeader` 삭제
- [x] refactor: 대시보드 상태를 `dashboard-view.tsx` 루트 컴포넌트 → `hooks/use-dashboards.ts` + `AppContext`로 이전
- [x] fix: 로그아웃 후 재로그인 시 대시보드/북마크 이전 계정 데이터 잔존 + 재로드 안 되던 2단계 버그 → [[issues/dashboard-account-switch-stale-state]]
- [x] fix: 대시보드 전환 시 화면 깜빡임(불필요한 리마운트) + 스크롤 불가(h-full 체인 끊김) → [[issues/dashboard-transition-height-chain-flicker]]
- [x] feat: 대시보드 "전체 새로고침" 시 위젯별 개별 스피너 표시(`forceRefreshing`)
- [x] docs: `dashboard-design.md`/`chat-design.md` 구조 변경 반영, 실제 코드와 어긋난 옛 서술 정정
- [x] feat(백엔드): 서비스 사용 매뉴얼 도구(`get_app_manual`) + `GET /api/v1/manual` 조회 API — 화면·LLM 단일 출처 공유, 이슈 #67 해결
- [x] docs(백엔드): 프론트 헤더 개편에 맞춰 매뉴얼 로그아웃/설정/관리자 진입 경로 설명 수정
- [x] knowledge: flex `h-full` 체인 누락 시 overflow-hidden 클리핑 트러블슈팅 문서화 → [[knowledge/troubleshooting/flex-height-chain-broken-by-missing-h-full]]
- [x] PR 생성·머지 — 프론트 [#66](https://github.com/DnA-Platform-Development-Team/dna-sql-agent-web/pull/66), 백엔드 [#96](https://github.com/DnA-Platform-Development-Team/dna-sql-agent/pull/96)(Closes #67)

## 2026-07-06 — 관리자 페이징, 다이얼로그 정리, 대화 제목 버그, 시스템 목록 성능 개선

- [x] fix: 새 대화 생성 시 첫 사용자 메시지로 제목 자동 갱신되던 규칙 복원(빈 문자열 센티널 회귀 수정) → [[issues/conversation-title-empty-string-sentinel-broken-by-default]]
- [x] feat: 관리자 목록(연결/시스템/사용자/그룹) 서버사이드 페이징 적용, 공통 페이지네이션 UI 통일 → [[decisions/021-admin-list-server-side-pagination]]
- [x] fix: 시스템 목록 API(`/systems`, `/systems/paged`) 응답 지연 — N+1 배치화 + `table_relation_info` 대용량 JSON 컬럼 SQL 단 축소 → [[issues/systems-list-api-slow-n-plus-one-and-heavy-json-column]]
- [x] fix: 설정 화면 슬라이더 소수점 입력 버그(즉시 반올림·DOM 미갱신·false dirty) 3종 수정 및 3개 탭 중복 구현 공통 컴포넌트로 통합 → [[knowledge/troubleshooting/react-controlled-number-input-same-numeric-value-no-dom-update]]
- [x] refactor: 죽은 `SchemaDetector` 컴포넌트 제거, DB 연결 저장 후 시스템 바로 생성 confirm 플로우 추가
- [x] refactor: 사용자/그룹 관리 화면 정리 — 미시행 `allowed_tables` UI 제거(프론트만, 백엔드 데이터/API는 유지), 중복 권한 상세 다이얼로그 제거
- [x] style: 채팅 전송 버튼 비활성 시 커서/한글화 정리, 커넥션 다이얼로그 풀 설정 라벨 줄바꿈 수정, 잔여 영어 tooltip/toast/title 한글화
- [x] PR 생성 — 프론트 [#67](https://github.com/DnA-Platform-Development-Team/dna-sql-agent-web/pull/67), 백엔드 [#99](https://github.com/DnA-Platform-Development-Team/dna-sql-agent/pull/99)
- [ ] (이월) 백엔드 `main` 브랜치 보호 확인됨 — 기존 "브랜치 없이 main에서 바로 작업" 메모리 재검토 필요
- [ ] (이월) PR #67·#99 리뷰/머지 대기
- [ ] (이월) 백엔드 `user_table_permissions`(테이블 단위 허용) 기능 완전 구현 여부 vs 완전 제거 여부 결정 필요

## 2026-07-09 — 채팅 북마크 이동, 지도 선택 중복 수정, 대시보드 고정 날짜·드래그 성능

- [x] feat: 채팅방 안에서 북마크된 카드로 바로 이동하는 네비게이터 — 검색 결과 이동 인프라 재사용, 헤더 토글·원형 순환 이전/다음, 검색 중 비활성화
- [x] fix: 지도 point 시각화 좌표+속성 완전 동일 행에서 다중 선택되던 문제 — 서버가 행 위치 기반 Feature.id 부여 → [[issues/map-point-duplicate-selection-same-coords-and-properties]]
- [x] feat+fix: 상대 날짜(오늘/최근 N일) SQL이 리터럴로 고정되어 저장 쿼리 갱신이 무의미해지던 문제 — 프롬프트 지시 변경(DB 동적 함수) + 대시보드 위젯 고정 날짜 감지·경고 UI 병행 → [[decisions/022-relative-date-dynamic-sql-and-fixed-date-detection]]
- [x] fix: 북마크 삭제해도 열려있는 대시보드에서 위젯이 안 사라지던 문제 — 삭제 성공 시 활성 대시보드 재조회 → [[issues/dashboard-widget-stale-after-bookmark-deleted]]
- [x] perf: 대시보드 편집 모드 드래그·드롭 시 지도 등 무거운 위젯 버벅임 개선 — React.memo/useCallback, will-change: transform, 그리드 설정 props 메모이제이션 → [[issues/dashboard-drag-drop-jank-heavy-widgets]]
- [x] knowledge: 드래그앤드롭 그리드 무거운 자식 리렌더 최적화 패턴 문서화 → [[knowledge/patterns/react-grid-drag-memoize-heavy-children]]
- [x] PR 생성 — 백엔드 [#104](https://github.com/DnA-Platform-Development-Team/dna-sql-agent/pull/104), 프론트 [#69](https://github.com/DnA-Platform-Development-Team/dna-sql-agent-web/pull/69)
- [ ] (이월) PR #104·#69 리뷰/머지 대기
- [ ] (이월) 대시보드 드래그 성능 — 사용자 체감상 개선됐으나 "완전히는 아님", 추가 여지 있으면 재검토

## 2026-07-16 — 그룹 관리자(Group Admin) 기능 정책 설계 + 백엔드 구현

- [x] docs: `docs/group-admin-design.md` 정책 문서 작성 (v0.1 → v0.3) — 그룹 관리자 역할,
      이중 레이어 권한 모델(그룹↔시스템 매핑 vs 사용자 권한), 커넥션 단독소유 편집 제한,
      그룹 이동 시 권한 전량회수 등 확정 → [[decisions/023-group-admin-role-and-permission-model]]
- [x] feat: 그룹 관리자 백엔드 구현 — 스키마(`group_system_mappings`, `group_admins`,
      `groups.is_default`), `require_group_admin`(DB 조회 기반) 인가 의존성, 신규
      `dna.group_admin` 모듈(CRUD + 라우터 28개 엔드포인트, 기존 `database/routes.py`
      핸들러 위임 재사용), `update_user`/`register` 정책 반영 버그 수정 겸함
- [x] test: `tests/test_group_admin.py` 16건 신규 (그룹 이동 권한 전량회수, 매핑삭제
      자동회수, 비활성화 시 즉시 역할해제, 단독소유 커넥션 판정, 대화이력 보존 회귀),
      기존 45건 회귀 없음 확인
- [x] (이월) 백엔드 커밋 및 PR 생성 — 2026-07-22 PR #117로 해소
- [x] (이월) `docs/group-admin-design.md` §7에 남은 세부 구현 판단 배포 전 최종 리뷰 — v0.9로 해소

## 2026-07-20 — 그룹 관리자 DB 관리 API 공용화, 권한 감사, 커넥션 정책 재조정

- [x] feat: `/group-admin/connections/paged`, `/group-admin/systems/paged` 신설 —
      admin과 동일한 서버 페이지네이션, 전체 목록을 클라이언트에서 자르던 방식 제거
- [x] fix: `SystemScopeResponse` pydantic 스키마 빌드 실패 — forward-ref가 서브클래스
      모듈 네임스페이스에서 해석되는 문제 → [[knowledge/troubleshooting/pydantic-forward-ref-resolved-in-subclass-module]]
- [x] security: 그룹 관리자 API 권한 체크 전수 감사 — `POST /group-admin/systems`가
      body의 `connection_id` 스코프를 검증 안 하던 구멍 발견
- [x] feat→revert: 커넥션 접근 정책 "생성자만 편집"(`created_by` 컬럼) 설계 후 보류,
      "임시로 시스템 관리자와 동일하게 전체 개방"으로 축소 — `_require_connection_visible`
      등 스코프 체크 코드 제거, `docs/group-admin-design.md` §4.1은 한 버전 전 상태로 남음
- [x] 백엔드 커밋 3건 (프론트엔드 세션은 [[projects/dna-sql-agent-web/sessions/2026-07-20-group-admin-db-tabs-unification]])
- [x] (이월) PR 생성 (백엔드/프론트 둘 다 미생성) — 2026-07-22 PR #117/#72로 해소

## 2026-07-20 — 그룹 관리자 정책 v0.5: 커넥션 접근을 "위임" 모델로 확정

바로 위 이월 항목("커넥션 접근 최종 정책 결정", "§4.1 재갱신") 해결.

- [x] docs: `docs/group-admin-design.md` v0.4 → v0.5 — 커넥션 CRUD는 시스템 관리자
      전용으로 되돌리고("생성자만 편집"/"공유 여부 무관 전체 편집 가능" 둘 다 폐기),
      대신 시스템 관리자가 그룹에 **커넥션을 위임**(N:M)하면 그 범위 내 시스템
      관리(생성·수정·삭제·지식화·SQL예제)를 그룹 관리자가 하는 구조로 확정
      → [[decisions/024-connection-delegation-model]]
- [x] 정책: `group_system_mappings`가 시스템 관리자가 수동 편집하던 기능에서, 커넥션
      위임으로부터 **자동 파생**되는 내부 상태로 전환 — 그룹 관리자가 만든 시스템은
      자기 그룹에만, 시스템 관리자가 만든 시스템은 위임받은 모든 그룹에 자동 매핑
- [x] 정책: 위임 해제 시 매핑 자동 해제 + 그룹 생성 시스템은 미사용(inactive) 전환 +
      해당 그룹 사용자의 `user_system_permissions`도 자동 회수 (기존 §4.1 회수 규칙
      연장 적용)
- [x] 그룹 관리자 기능이 아직 미출시라 소급 마이그레이션 없이 강제 적용하기로 결정
- [ ] (이월) 구현 착수 필요 — `group_connection_mappings` 신규 테이블/CRUD API,
      기존 "임시 전체 개방"이던 그룹 관리자용 커넥션 CRUD 엔드포인트 제거·조회 전용화,
      시스템 생성 시 자동 매핑 로직, 위임 해제 시 캐스케이드(매핑 해제·미사용 전환·
      권한 회수) 트랜잭션
- [ ] (이월) 프론트엔드: 그룹 관리자 화면의 연결 관리에서 등록/수정/삭제 UI 제거
      (현재는 admin과 동일하게 전체 CRUD 노출된 상태, [[projects/dna-sql-agent-web/sessions/2026-07-20-group-admin-db-tabs-unification]] 참고)
- [x] (이월) wiki: 구현 착수 시 `docs/group-admin-design.md` §6 개발 범위 표를 실제
      커밋과 대조해 갱신 — 아래 2026-07-21 섹션에서 해소

## 2026-07-21 — 그룹↔커넥션 위임 구현 완료, 기본 그룹 접근 버그 수정

바로 위 2026-07-20 이월 항목(구현 착수, 프론트 CRUD UI 제거) 전부 해소.

- [x] feat: `group_connection_mappings` 테이블 + CRUD API 신설
      (`GET/POST/DELETE /admin/groups/{id}/connections`, 역조회
      `GET /admin/connections/{id}/groups`) → `63268d6`
- [x] feat: 레거시 그룹↔시스템 수동 매핑 관리자 API 4개 제거 — 매핑은 이제
      위임에서 전부 자동 파생 → `63268d6`
- [x] feat: 그룹 관리 다이얼로그용 서버 페이징+정렬(이미 선택된 항목 우선) API
      3종 추가 — 커넥션 후보, 그룹 관리자 후보, 멤버 후보 → `4d96be0`
- [x] fix: `move_user_group()`이 대상 그룹과 무관하게 `default_grant` 매핑만
      보던 버그 수정 — 기본 그룹(그룹 관리자 없음)으로 이동/재편입 시에는
      `register()`와 동일하게 `systems.default_accessible` 기준으로 재부여.
      실제로는 기본 그룹 재진입 시 권한이 0개로 초기화되던 버그였음
      → [[decisions/025-default-group-access-initialization]], `a70bbe7`
- [x] feat: 기본 그룹에는 그룹 관리자 지정/커넥션 위임 자체를 서버에서 거부
      (422) → `a70bbe7`
- [x] test: `test_group_admin.py` 보강, 17건 전부 통과 확인 (`PYTHONPATH=src` +
      더미 `DB_ENCRYPTION_KEY` 필요 — 로컬 환경에 두 값 다 안 잡혀 있어 첫 실행
      시 `ModuleNotFoundError`/`KeyError`로 헷갈릴 수 있음)
- [x] docs: `group-admin-design.md` v0.5 → v0.6 (§4.3 예외 조항, §7 #11,
      변경로그)

## 2026-07-22 — 그룹 관리자 기능 마무리, PR #117 머지

바로 위 2026-07-21 이월 항목("PR 생성", "docs §7 최종 리뷰" 관련) 대부분 해소.

- [x] feat: 커넥션 위임 시 `default_grant` 자동 시딩(`default_accessible`
      시스템 최초 1회) → [[decisions/026-group-admin-v0.9-refinements]]
- [x] feat: 사용자별 권한 매트릭스 그룹 선택 필수화 + 컬럼 그룹 스코프 제한
      (admin/기본 그룹 예외)
- [x] feat: 벌크 그룹 이동 `POST /admin/users/bulk-move` (단일 트랜잭션)
- [x] feat: 그룹 편입 후보 페이징 전환, 연결/시스템 이름 검색+정렬 추가
- [x] fix: `/me` JWT 스탈 그룹명 → DB 조회 전환, 멤버 다이얼로그 `is_admin`
      스코프 오류, 커넥션 위임 해제 캐스케이드, 다수 정렬 버그
      (`COLLATE "und-x-icu"`) → [[knowledge/troubleshooting/postgres-collate-korean-english-mixed-sort]]
- [x] docs: `group-admin-design.md` v0.9, 그룹 관리자 전용 매뉴얼 신설
- [x] test: `test_group_admin.py` 9건 추가, 총 19건 전부 통과
- [x] PR #117 생성·머지 (백엔드), 프론트 PR #72도 동일 세션에 머지
      ([[projects/dna-sql-agent-web/sessions/2026-07-22-group-admin-hardening-and-pr72]])
- [ ] (이월) `app_manual_group_admin.md` 소제목 중복 정리 (의도적 보류)
- [ ] (이월) 챗봇 `AppManualTool`이 그룹 관리자 인지 못함 — 범위 밖으로 남김

## 2026-07-24 — 배포 이미지 소스 보호 (Nuitka 컴파일)

- [x] feat: `Dockerfile` 멀티스테이지 전환 — `dna`, 로컬 `vanna` 포크를 Nuitka로 파일 단위
      컴파일(`.py`→`.so`), 원본 `.py`/`.pyc` 이미지에서 제거 → [[decisions/027-nuitka-source-compilation]]
- [x] fix(시행착오): 서드파티(torch 등) 포함 전체 standalone 컴파일 OOM 반복 실패 →
      자체 코드만 컴파일하는 방식으로 전환
- [x] fix(시행착오): 패키지 단위 컴파일 시 파일 하나로 뭉쳐져 데이터 파일 경로(`Path(__file__)`)
      깨짐 → 파일 단위 컴파일로 전환
- [x] fix(시행착오): rsync 필터 순서 실수로 `__pycache__/.pyc`가 최종 이미지에 유출(디컴파일
      가능한 구멍) → 필터 순서 수정
- [x] docs: `docs/nuitka-build-design.md` 신설(상세 설계·시행착오 전체 기록), `architecture.md`
      기술 스택 표·관련 의사결정 갱신
- [x] 로컬 검증: `.env` 기반 컨테이너 기동 → `Application startup complete`, `/docs`·
      `/openapi.json` HTTP 200 확인
- [x] Colima 트러블슈팅: VM `vz` 드라이버 disk lock 문제(`colima delete` 재생성으로 해결),
      메모리 부족(2GiB→8GiB) → [[knowledge/tools/colima]] 신설
- [x] 커밋 `f3abe40` (`feat/nuitka` 브랜치), 원격 push는 아직 안 함
- [ ] (이월) `main.py`도 컴파일 범위에 포함할지 결정

## 2026-07-28 — self-hosted 러너 디스크 풀 대응 + 이미지 빌드 컨텍스트 보안 강화

- [x] self-hosted 러너(`sdn04`) `No space left on device` 장애 원인 규명 — `docker buildx`
      캐시 149.7GB 무제한 누적 → [[issues/self-hosted-runner-disk-full-buildx-cache]]
- [x] `docker buildx prune -af` 안내로 디스크 회수 (self-hosted 러너에서 실제 빌드 검증 이월
      항목이 막혀있던 원인 해소)
- [x] `Dockerfile`에 `.dockerignore` 부재 확인 → 신설(`docs`, `.git`, `.github`, `.claude`,
      `venv`, `__pycache__`, `tests` 등 제외), 커밋(`08a57bb`) 후 `feat/nuitka` push
      → [[decisions/028-image-build-context-minimization]]
- [x] `requirements.txt` 등 레이어 히스토리까지 완전 제거가 필요한 파일 처리 패턴 설계
      (버려지는 `context` 스테이지) → [[knowledge/patterns/docker-multistage-context-stage-strip-secrets]]
- [x] `requirements.txt`용 `context` 스테이지 반영 여부 재검토 — **적용 안 하기로 결정 (2026-07-29)**.
      실제 확인 결과 `requirements.txt`엔 자격증명 없이 패키지명+버전만 있어 노출 리스크가
      낮고, 얻는 보안 이득 대비 Dockerfile 복잡도 비용이 안 맞음 → 보류
- [ ] (이월) self-hosted 러너에서 실제 빌드 검증 — 디스크 공간은 확보했으니 재시도 가능
- [ ] (이월) buildx 캐시 자동 정리(cron 또는 buildkitd `gcpolicy`) 설정 — 재발 방지
- [ ] (이월) `.env`가 컨테이너 런타임에 파일로 직접 읽히는지 확인 후 `.dockerignore`
      `.env` 제외 여부 재검토

## 2026-07-29 — `.pyi` 유출 실제 수정 + 시크릿 관리 점검

- [x] `.pyi` 유출 위험 패턴(함수 기본값/모듈·클래스 상수) AST 정밀 스캔 — `schema.py`,
      `vectorization/prompts.py`, `sql_collectors/summarizer.py`, `bi_slide/template_selector.py`,
      `relation_info_generator.py` 확인
- [x] Nuitka `--no-pyi-file` 옵션 발견·적용 — `.pyi` 생성 자체 차단, `Dockerfile`·
      `docs/nuitka-build-design.md` §3.4 반영 → [[decisions/027-nuitka-source-compilation]],
      [[knowledge/patterns/nuitka-no-pyi-file-prevents-stub-leak]]
- [x] PR #125 생성 (feat/nuitka → main). 로컬 `main` stale 상태로 diff를 잘못 설명한 실수
      발생, 사용자가 직접 정정 → [[knowledge/troubleshooting/git-diff-stale-local-branch-shows-merged-commits-as-new]]
- [x] `JWT_SECRET_KEY` 하드코딩 기본값 fallback 발견 (`jwt_utils.py:15`) → [[issues/jwt-secret-key-hardcoded-fallback-default]]
- [x] `.env`가 origin에 커밋된 것 확인 — 처음엔 유출로 오판했으나, private 레포 내 팀 공유
      목적의 의도된 관례임을 사용자 확인으로 정정 (문제 아님)
- [ ] (이월) `JWT_SECRET_KEY` fallback 기본값 제거 (없으면 기동 실패시키는 방향)
- [ ] (이월) `schema.py`/`prompts.py` 등 모듈 상수 데이터 파일 분리·암호화 여부 결정 (PR #125 논의)
- [ ] (이월) PR #125 정리 — 사용자가 직접 처리하겠다고 함

## 2026-07-31 — 대화 시스템 권한 우회 취약점 수정

- [x] 취약점 분석 — 클라이언트가 요청 `metadata` 로 보낸 `system_name`/`connection_name`/
      `database_id` 를 서버가 검증 없이 사용. 조작 시 권한 없는 System 조회 가능.
      `chat_sse` 외 `chat_websocket`, `chat_poll` 도 동일 경로
      → [[decisions/029-conversation-system-scope-server-side]]
- [x] `crud.get_authorized_system_scope` / `get_authorized_scope_for_conversation` 추가 —
      스코프 조회와 권한 검증을 단일 쿼리로 묶어 호출부의 체크 누락 차단
- [x] 대화 생성 API 를 `system_id`(UUID) 기반 + 권한 체크로 전환 (없으면 403).
      `system_name` 은 커넥션 단위로만 유일해 이름 단독 조회 시 동명 시스템 오선택 발생했음
- [x] 채팅 엔드포인트 3곳 — 클라이언트 `metadata` 미사용, `conversation_id` 로 대화
      레코드에서 스코프 확정 후 주입. 매 요청 권한 재확인(회수 즉시 반영)
- [x] 우회로 차단 — 스코프 덮어쓰기 경로 2곳 제거, DB 에 없는 `conversation_id` 거부
- [x] fix: 권한 회수 상태에서 메시지 저장 시 대화의 시스템 정보가 NULL 로 덮어써져
      영구 유실되던 버그 (`ChatSaveHook` 의 `ON CONFLICT DO UPDATE`)
- [x] fix: 삭제된 시스템의 대화가 동명의 다른 커넥션 시스템으로 표시되던 문제 —
      `(connection_name, system_name)` 쌍 매칭으로 변경
- [x] fix: 접근 불가 대화를 403 으로 응답하고 프론트가 안내 후 홈으로 이동
- [x] refactor: `database_id` 가 `connection_name` 의 레거시 별칭임을 확인, 저장 대신
      파생으로 통일 (`COALESCE`)
- [x] refactor: 대화 URL 에서 `conversation_id` 제거 — localStorage 인증이라 서버가
      검증할 수 없어 사실상 장식이었음 → [[issues/chat-url-conversation-id-decorative]]
- [x] docs: `multi-db-design.md`, `user-management-design.md` 갱신
- [x] PR #127(백엔드 8커밋), PR #75(프론트 7커밋) 생성·머지 (2026-08-03)
- [x] fix: 대시보드 → 대화목록 이동이 삭제된 `/chat/[id]` 라우트로 향하던 문제 (2026-08-03)
- [ ] **백엔드·프론트 동시 배포** — `POST /api/v1/chat` 계약 변경(`system_id` 필수)
- [ ] 기본 DB(`.env` `"default"` runner) 접근 정책 결정 — 아래 두 이슈가 여기 걸려 있음
- [ ] (미해결) 스코프 없으면 테이블 접근 제한이 사라짐(fail-open)
      → [[issues/sql-guard-fail-open-when-scope-absent]]
- [ ] (미해결) 권한 회수 후 대화 이력의 이전 시스템 테이블명이 LLM 문맥에 남음
      → [[issues/conversation-history-retains-revoked-system-tables]]
- [ ] 예외 원문이 클라이언트로 노출되는 문제 — `except Exception` 이 `str(e)` 를 전달하고
      프론트가 채팅창에 렌더. DB 에러 원문으로 스키마 탐색 가능
- [ ] `conversations.database_id` 컬럼 DROP + 응답 필드 제거
- [ ] conversation id 엔트로피 — `conv_{hex[:8]}` = 32비트, 8만 건에서 충돌 확률 50%
- [ ] (장기) vanna 코어에 System 개념 추가해 `user.metadata` 에서 스코프 분리 —
      `SystemPromptBuilder`/`LlmContextEnhancer`/`ToolContext` 인터페이스 변경 필요
- [ ] (장기) 세션(httpOnly 쿠키) 인증 전환 후 `/chat/[id]` 서버 검증과 함께 재도입

## 2026-08-03 — 채팅 요청 경로의 중복 DB 조회 정리

- [x] 중복 실측 — `chat_sse` 1건당 고정 8회 + SQL 실행 횟수. 스코프 확정 쿼리와
      `get_conversation` 이 같은 대화 행을 두 번 읽고, 프롬프트 빌더와 SQL 가드가 같은
      그룹 권한을 각각 조회, 가드는 SQL 실행마다 반복
- [x] `get_conversation` 의 존재 확인·소유권 확인을 한 쿼리로 통합, 죽은 스코프 컬럼 제거
- [x] 그룹 테이블 권한을 프롬프트 빌더·SQL 가드가 공유 — 프롬프트에 알리는 정책과 실제
      차단 기준이 같은 소스가 되는 효과도 있음
- [x] 스코프 확정 쿼리에서 `system_prompt`/`dialect`/`version` 을 함께 읽어 재사용.
      `RequestContext.metadata` 로 나르면 로그에 프롬프트 본문이 통째로 찍혀 요청 단위 캐시 사용
- [x] `request_scope` 모듈 — 캐시 생성·일괄 초기화. 여기서 만든 것만 초기화 대상이라
      캐시 추가 시 WebSocket 초기화를 빠뜨릴 수 없음
      → [[knowledge/patterns/request-scoped-cache-with-contextvars]]
- [x] WebSocket 루프 시작 시 캐시 초기화 — 연결 하나가 여러 메시지를 처리해 컨텍스트가
      이어지므로 비우지 않으면 권한 회수가 반영되지 않음 (현재 프론트는 WS 미사용, 사전 차단)
- [x] fix: `get_conversation` 소유자 비교를 UUID 로 — SQL `WHERE` 를 파이썬 문자열 비교로
      옮기며 Postgres 정규화가 사라져 JWT `sub` 표기가 다르면 소유자가 거부될 수 있었음
- [x] `crud._authorized_scope` → `_scope_from_row` 개명 (routes 의 동명 판정 함수와 혼동)
- [x] `tests/test_request_scoped_cache.py` 6건 추가 — 요청 내 재사용, 요청 간 격리,
      한 태스크가 여러 메시지 처리 시 격리(WS 회귀 방지), 그룹별 키 분리, 신규 캐시 등록
- **결과: 고정 8회 → 5회** (SQL 3회 실행 시 11회 → 5회). 실서버 로그로 캐시 HIT 확인
- [ ] `refactor/chat-request-query-dedup` PR 생성 — 커밋 1건, 푸시 완료, PR 미생성
- [ ] `conversations` 헤더도 캐시에 담으면 5회 → 4회. 캐시 대상이 늘수록 수명 관리 실수
      여지도 커져 보류
- [ ] (사소) 병렬 태스크에서 캐시 히트율 저하 — 자식이 `set()` 한 값이 부모로 안 돌아옴.
      정확성 무관
- [ ] remote URL 에 PAT 평문 노출 — credential helper 나 SSH 로 전환, 토큰 rotate 권장

## 2026-08-03 — 오피스 기능 고도화 착수 (기한: ~08/31 1차 프리징)

착수 시점: 2026-08-10 주. 기한: 2026-08-31 1차 프리징.

**지금까지**
- [x] 서버에서 PPT 슬라이드를 생성하고 프론트가 반영하는 기능 — 팀장님 개발 완료
- [x] 설계 변경 — 서버는 데이터만 생성하고 화면 구성은 프론트가 담당하는 구조로
      실장님 재개발 완료. 슬라이드 렌더링 책임이 서버에서 프론트로 이동
      (ADR-007 의 "레이아웃은 프론트 소유" 방향과 같은 계열)
- [x] LLM 역할 분리 — 데이터 추출(LLM API) / 화면 레이아웃 생성(LLM API)
- [x] 스타일 레이아웃 5종 중 사용자가 고르면 LLM 이 다시 그리는 흐름

**현재 상태**
- 구현 디자인이 전부 미완이고 오류가 남아 있는 상태. 동작 확인 가능한 수준이 아님

**참고 — 2026-08-05 에 정리된 것 (고도화 착수 전 발판)**
- 보고서용 LLM 접속정보의 출처가 `.env` 하나로 확정됨. 고도화하면서 설정 위치를
  다시 고민할 필요 없음. 질의응답 LLM(`llm_connections` 테이블)과 완전히 분리
- 보고서 API 실패 경로가 상태 코드로 구분됨 → 프론트가 상황별 안내를 띄울 수 있음
  - `503` 보고서용 LLM 미설정 / `500` 생성 실패 / `404` 대상 대화 없음
- 예외 원문이 화면으로 나가던 것을 막음. 원인은 로그에만 남으므로,
  고도화 중 디버깅은 `agent.log` 를 봐야 함

**할 일**
- [ ] 실장님 설계대로 기능 고도화
- [ ] 디자인 미완 항목 정리 + 오류 목록화 → 우선순위 확정 (프리징 범위 산정의 전제)
- [ ] excel, word 에서도 특화 기능 제공하도록 개발
- [ ] 설계 변경 경위·현재 구조를 ADR 로 분리 기록 (status.md 메모의 "PPT 추가기능 동작 흐름" 대체)

## 2026-08-04 — 고객사 배포 패키지 구축

소스 접근 없이 타 사이트에 전달할 수 있는 배포 체계를 만들었다.
→ 세션: [[projects/dna-sql-agent/sessions/2026-08-04-customer-delivery-package]]

- [x] 배포 전용 저장소 신설 — `dna-sql-agent-deploy` (private)
      → ADR: [[projects/dna-sql-agent/decisions/030-deploy-package-separate-repo]]
- [x] `package.sh` — 빌드 → `docker save` → 시크릿 검사 → zip, 사이트·버전·일시별 산출물
- [x] `init.sh` / `start.sh` — 키 생성·이미지 로드·웹서버 선택·관리자 계정 발급·기동 대기
- [x] `INSTALL.txt` — 터미널에서 읽는 평문 설치 안내서
- [x] 시크릿을 패키지에 넣지 않고 고객사에서 생성 (gitleaks + 자체 검사로 차단)
- [x] `.dockerignore` 정리 — 빌드 컨텍스트 114MB → 10.7MB
- [x] 마운트 폴더 소유권을 엔트리포인트에서 처리 (설치자 `sudo` 불필요)
      → ADR: [[projects/dna-sql-agent/decisions/031-container-mount-ownership-entrypoint]]
- [x] `DB_MODE`/`VECTOR_MODE` — 내장·외부를 명시하고 외부면 컨테이너 미기동
- [x] 웹: `allowedDevOrigins` 가 프로덕션 빌드에 남지 않도록 분기

**현재 상태**
- 로컬 리허설로 5개 컨테이너 기동·`/health` 200 확인
- `chore/deploy-hardening` 은 push 완료, PR 은 아직 없음 (2026-08-05 기준 ahead 15)

**할 일 (배포 전 필수 — 폐쇄망인 경우)**
- [ ] 임베딩 모델을 이미지에 번들링 — 현재 런타임에 HuggingFace 에서 받아 폐쇄망 기동 불가
- [ ] Qdrant 서버 버전을 클라이언트(1.17)에 맞추기 (현재 1.12.4)

**할 일 (소스 정리)**
- [x] `qdrant`·`database` 를 `.env` 직독으로 변경 (2026-08-05 완료)
      → 아래 2026-08-05 항목 참고
- [ ] 관리자 부트스트랩 — 가입자가 전부 일반 그룹이라 DB 를 직접 고치지 않으면
      아무도 관리자가 될 수 없음
- [ ] LLM 미등록 시 명확한 안내 (현재는 로그인은 되고 답변만 안 됨)
- [x] dev 워크플로 체크아웃 브랜치를 `main` 으로 복구

**할 일 (개선)**
- [ ] CPU 전용 torch 로 이미지 축소 (16.3GB → 6~7GB 예상)
- [ ] `upgrade.sh`, `pigz` 병렬 압축, `pv` 진행률

## 2026-08-05 — 설정 출처 일원화, 배포 패키지 워크플로

같은 값이 `.env` 와 `config/*.json` 양쪽에 있어 한쪽만 고치면 조용히 갈라지던
구조를 정리하고, 패키지 생성을 워크플로로 옮겼다.
→ 세션: [[projects/dna-sql-agent/sessions/2026-08-05-config-source-unification-and-package-workflow]]
→ ADR: [[projects/dna-sql-agent/decisions/032-connection-info-env-single-source]]

**계기가 된 사고**
- `start.sh` 로 기동했는데 `asyncpg InvalidPasswordError` 로 죽음.
  `.env` 는 맞았는데 앱이 첫 기동 때 만들어진 `config/database.json` 의
  옛 비밀번호를 읽고 있었다. Qdrant 도 같은 이유로 닫힌 포트를 물고 있었음
- **`.env` 는 최초 기동 시 config 를 만드는 씨앗일 뿐**이라는 구조가 원인.
  설치 중 접속정보를 바로잡아도 반영되지 않는다

**접속정보를 `.env` 직독으로**
- [x] `dna/settings/env_config.py` 신설 — DB·Qdrant·보고서 LLM 을 환경변수에서 직접 읽음
- [x] 기본값을 코드에 두지 않음. 값이 비면 기동을 중단하고 무엇이 비었는지 알림
      (예전 `defaults/database.json` 은 내부 IP `192.168.101.129` 로 조용히 폴백했음)
- [x] `SECTIONS` 에서 `database`·`qdrant`·`llm` 제외 → 설정 API 의 DB 비밀번호·
      api_key 평문 노출 해소. 기존 설치본의 해당 파일은 기동 시 삭제
- [x] DSN 조립에 `quote()` 적용 — 비밀번호에 `@ : /` 가 있으면 깨지던 문제

**설정 초기값 출처를 기본값 하나로**
- [x] `rag`·`embedding` — `.env` 덮어쓰기 제거. `_migrate_embedding` 은 `.env` 가
      비면 `model: ""` 을 저장해 모델을 못 여는 버그가 있었음
- [x] `masking` — 레거시 `masking_rules.json` 삭제. `defaults/masking.json` 과
      규칙은 같은데 `default_group_action` 만 달랐다(`none` vs `mask`)
- [x] 마스킹 기본 동작을 `mask`(fail-closed)로 통일 — 전략에 없는 그룹이
      개인정보 원본을 보던 상태였음. 정의가 세 곳(defaults·레거시·스키마)이었다
- [x] `observability` — 자격증명을 설정 파일에서 제거(평문 `secret_key` 저장됨).
      켜짐 판정을 `dna/observability/enablement.py` 로 일원화. 예전에는
      `agent_service` 가 `.env` 키만 있으면 화면 설정을 무시하고 강제로 켰음
- [x] `.env` 에서 더 이상 읽지 않는 12줄 제거

**보고서 API**
- [x] 보고서용 LLM 을 `.env` 직독으로. 질의응답 LLM(`llm_connections` 테이블)과
      역할이 완전히 분리됨. `config/llm.json` 을 읽던 곳은 `ppt_slide_service` 한 곳뿐이었다
- [x] 예외 원문이 클라이언트로 나가던 것 일반화 (`0ede9b1` 이 대화 API 에
      적용한 것과 같은 조치). DSN 이 그대로 응답에 실릴 수 있었음

**배포 스크립트 (dna-sql-agent-deploy)**
- [x] `init.sh` 가 외부 DB 사용 시 `DB_ENCRYPTION_KEY` 를 새로 만들지 않도록 수정.
      기존 데이터를 복호화하지 못하는데 **기동은 성공하고 `/health` 도 200** 이라
      "설치 완료" 로 안내된 뒤 운영 중에야 드러나던 문제
- [x] `start.sh` 가 복호화 실패를 성공으로 보고하지 않도록 검사 추가

**배포 스크립트 (dna-sql-agent-deploy)**
- [x] `init.sh` 가 외부 DB 사용 시 `DB_ENCRYPTION_KEY` 를 새로 만들지 않도록 수정.
      기존 데이터를 복호화하지 못하는데 **기동은 성공하고 `/health` 도 200** 이라
      "설치 완료" 로 안내된 뒤 운영 중에야 드러나던 문제
- [x] `start.sh` 가 복호화 실패를 성공으로 보고하지 않도록 검사 추가
- [x] 같은 태그 이미지로 로드를 건너뛸 때 교체 절차 안내 (조용히 넘어가던 것)
      → 이슈: [[projects/dna-sql-agent/issues/same-tag-image-load-skipped]]
- [x] 산출물 경로 단순화 — 버전 폴더 제거, 이름 하나에 사이트·버전·일시를 담음
      `dist/<사이트>/dadap_<사이트>_<버전>_<yyyyMMddHHmmss>/`
- [x] `DIST_DIR`·`MIN_FREE_GB` 추가. 여유 공간이 부족하면 빌드 전에 중단.
      오래된 산출물은 자동 삭제하지 않고 목록만 보여 줌 (전달한 zip 이 곧 기록)
- [x] `pigz` 지원 — 있으면 병렬 압축, 없으면 `gzip` 폴백
- [x] `INSTALL.txt` 에서 운영·문제 해결을 `README.txt` 로 분리
- [x] 웹 컨테이너의 호스트 포트를 닫아 nginx 우회 접속 차단

**배포 패키지 생성 워크플로 (신규)**
- [x] `dna-sql-agent-deploy/.github/workflows/package.yml`
- [x] 빌드 서버 러너에서 실행, 산출물은 그 서버(`/DATA/dadap-packages`)에 남김
      — 한 벌이 4GB 이상이라 GitHub 아티팩트로 왕복시키지 않음
- [x] 기본은 **빌드하지 않고** 서버의 `latest` 이미지를 묶음.
      `rebuild` 를 켤 때만 소스 저장소를 체크아웃
- [x] 버저닝은 도입하지 않음 — 기존 배포 방식에 없으므로. `version` 은 패키지
      파일 이름에 붙는 라벨이며 이미지 태그 체계가 아니다
- [x] 도구·권한·이미지 확인을 앞단에 배치 (수 분 뒤 실패 방지)
- [x] 첫 실행으로 검증 — `gitleaks` 미설치가 잡혔고, 설치 후 패키징 성공

**문서**
- [x] `docs/configuration-reference.md` 신설 — `.env` 와 `config/*.json` 의 정본.
      각 값의 목적·구성·왜 그 자리인지
- [x] 폐기된 `llm.json`·`masking_rules.json` 참조를 전 문서에서 제거

**남은 것**
- [ ] `chore/deploy-hardening` PR 생성 → main 머지
- [ ] 서버 `latest` 이미지가 커진 원인 확인 — 로컬 tar 3.8GiB vs 서버 6.6GB+
      (`docker history dna-sql-agent:latest` 로 큰 레이어 확인)
- [ ] 빌드 서버에 `pigz` 설치 — gzip 이 코어 하나만 쓰는 것을 `top` 으로 확인함
      (전체 CPU 13.8%, gzip 100%)
- [ ] 웹 저장소 `chore/deploy-hardening` 브랜치 push (원격에 없음)
- [ ] 3개 배포 워크플로 트리거가 `workflow_dispatch` 전용으로 바뀐 것이 의도인지 확인
- [ ] 스키마 기본값 ↔ `defaults/*.json` 불일치 정리 (아래 분석 참고)
- [ ] 설정 API 의 `ValidationError` 를 400/422 로 변환 — 지금은 CORS 헤더 없는
      500 이 되어 화면에 사유가 전혀 안 보임

### 분석 — 스키마 기본값과 `defaults/*.json` 의 이중 출처 (2026-08-05 조사)

같은 설정의 "기본값"이 두 곳에 있고 값이 다르다. `defaults/*.json` 은 실제로
`config/*.json` 을 만들 때 쓰는 값이고, `schemas.py` 의 Pydantic 필드 기본값은
검증용 모델에 붙어 있는 값이다.

| 섹션 | 항목 | `defaults/*.json` | `schemas.py` |
|---|---|---|---|
| `rag` | `mode` | `"tool"` | `"enhancer"` |
| `rag` | `system_classification.default_systems` | `["IFIS"]` | `["IF"]` |
| `agent` | `max_conversation_messages` | `50` | `20` |
| `audit` | `include_full_ai_responses` | `true` | `false` |
| `embedding` | `model` | `upskyy/bge-m3-korean` | `""` |
| `masking` | `strategies` | 규칙 8종 | `{}` |
| `tool_access` | `tools` | 도구 목록 | `[]` |
| `audit` | `ui_features` | 4개 항목 | `[]` |

**지금은 문제가 없다.** 스키마 기본값이 어느 경로로도 저장되지 않기 때문이다.

- `routes.py` 의 `put_section`·`patch_section` 이 `validate_section()` 의 반환값을
  **버리고** 원본 body 를 저장한다. 기본값이 채워진 결과는 쓰이지 않는다
- `GET` 은 `load()` → `config/*.json` 또는 `defaults/*.json` 이라 스키마를 안 거친다
- `/settings/{id}/schema` 엔드포인트는 프론트가 호출하지 않는다

**언제 위험해지나.** `validate_section()` 의 반환값을 저장하도록 바꾸는 순간
데이터 손실이 된다. 부분 PUT 에서 `masking.strategies` → `{}`,
`tool_access.tools` → `[]` 로 덮여 규칙·도구 목록이 통째로 사라진다.
실제로 2026-08-05 에 "부분 PUT 이 나머지 설정을 지운다"는 버그를 그 방식으로
고쳤다가, 이 불일치 때문에 방향을 바꿨다.

**왜 기본값이 붙어 있나.** 프론트가 `deepDiff` 로 바뀐 필드만 PATCH 하는데,
그 부분 body 를 그대로 `model_validate()` 에 넣기 때문이다. 기본값이 없으면
누락 필드로 검증에 실패한다. 즉 **검증을 통과시키기 위한 장치**이지 값으로
의도된 것이 아니다.

**고칠 방향 — 검증 시점을 병합 뒤로.** 지금은 병합 전에 부분 body 를 검증한다.
병합 후 완전한 설정을 검증하면 모든 필드가 채워져 있어 기본값이 발동하지 않고,
클래스에서 지워도 된다. 값의 출처가 `defaults/*.json` 하나로 확정된다.
제약(`gt=0`, `pattern`)은 그대로 살아 있고, 오히려 병합 결과의 유효성까지
확인할 수 있어 검증이 더 정확해진다.

같이 처리해야 할 것:
- `ValidationError` 를 400/422 로 변환. 지금은 그대로 올라가 **CORS 헤더 없는
  500** 이 되고 브라우저가 `TypeError: Failed to fetch` 로 막아, 화면에 사유가
  전혀 표시되지 않는다 (2026-08-05 에 실제로 이것 때문에 원인 추적이 오래 걸림)
- 부분 PUT 이 나머지를 지우는 문제. 프론트는 `PUT` 을 쓰지 않아(`patchSection`
  만 사용) 실사용 경로로는 노출되지 않지만, API 직접 호출·파일 수동 편집 시 발생

**컬렉션 필드는 값을 맞추는 방식으로 풀 수 없다.** `strategies`·`tools`·
`ui_features` 의 내용을 `schemas.py` 에 넣으면 마스킹 규칙 8종을 파이썬 코드에
한 벌 더 복제하는 셈이라, 이번에 없앤 이중 출처를 다시 만든다. 스칼라 값
(`rag.mode`, `agent.max_conversation_messages` 등)만 맞추고, 나머지는 위 구조
변경으로 푸는 것이 맞다.

**참고**
- `collection_runner` 는 9개 필드가 스키마에서 `null` 이지만 `DEFAULT_ONLY_SECTIONS`
  라 `load()` 가 항상 defaults 를 반환한다. 영향 없음
- `sql_guard.groups` 는 스키마에만 남은 잔재. 그룹별 테이블 권한은 DB 로 이관됨
- `rag.system_classification.default_systems` 의 `IFIS` vs `IF` 는 어느 쪽이
  맞는지 확인 필요

## 2026-08-06 — 임베딩 모델 폐쇄망 조사 + 배포 하드닝 1차 마무리

세션 로그: [[projects/dna-sql-agent/sessions/2026-08-06-embedding-bundling-research-and-deploy-prs]]

### 완료

- [x] `chore/deploy-hardening` PR 생성 — 백엔드 `#131`(24커밋), 웹 `#76`(3커밋)
- [x] 웹 저장소 `chore/deploy-hardening` 브랜치 push (원격에 없던 것)
- [x] 머지 전 정리 — `dna-sql-agent_dev.yml` 의 `ref` 하드코딩을 `main` 으로 되돌림(`ad39d1d`).
      안 되돌리면 머지 후 브랜치 삭제 시 DEV 배포가 깨진다
- [x] 웹 `172.16.1.7` 제거 — 출처 불명. `addin.dnadev.com` 만 남김(`daaa173`)
- [x] 배포 저장소 커밋 4건 main 푸시 — pigz 압축, 워크플로 옵션, `site` 입력 주석,
      **boolean 조건 버그 수정**(`86e96ff`)
- [x] 서버 `latest` 이미지가 커진 원인 확인 — 아래
- [x] 검증 — 백엔드 `pytest` 56개 통과, 웹 프로덕션 빌드 + 산출물에 사내 주소 없음

### 이미지 용량 실측 — 콘텐츠 8.08GB 중 4.2GB 가 미사용 CUDA

| 항목 | 크기 |
|---|---|
| `nvidia-*-cu12` | 2.8GB |
| `triton` | 419MB |
| `torch/lib/libtorch_cuda*.so` + `libcusparseLt` | 931MB |
| `chromadb` 계열 (onnxruntime·kubernetes·rust_bindings) | ~200MB |
| 빌드 전용 도구 (nuitka·mypy·pytest·zstandard) | ~110MB |

휠 실측: `torch-2.2.2+cpu` **178MB** vs `+cu118` **781MB**.

`requirements.txt` 의 `--find-links .../cu118` 은 **동작하지 않고 있었다** —
설치된 것은 PyPI 기본 cu121 휠(`nvidia-*-cu12`). `--find-links` 는 우선순위를
강제하지 않는다. `--index-url` 이어야 한다.

`chromadb` 는 `src/dna/` 어디서도 import 하지 않는다(pip `vanna` 도 요구 안 함).

### 임베딩 모델 폐쇄망 — 조사 결과

대상은 `upskyy/bge-m3-korean` 하나(2.1GB safetensors). **색인과 질의 양쪽**에
쓰이므로 없으면 RAG 가 동작하지 않는다. 로드는 세 곳이며 셋 다 HF repo id 를
`SentenceTransformer` 에 그대로 넘긴다. `orchestrator.py:54` 는 config 를 무시하고
모델명·device 를 하드코딩한다.

**다운로드 시점은 "최초 검색"이 아니라 "기동"이다** — `agent_service.py:136` 이
모듈 레벨이라 앱이 뜨면서 로드한다. 배포 `README.txt` 의 "최초 검색 시 내려받습니다"
는 사실과 다르며, 폐쇄망에서는 기동 자체가 막힌다.

**방향 전환:** CPU 전용 단일 이미지로 4.2GB 를 줄이려 했으나, **원격 배포가
`device: cuda` 로 실사용 중**임을 확인. `.env.template`·`README.txt` 에 GPU 전환이
이미 문서화되어 있어 CPU 전용은 약속을 깨는 것이 된다. **CPU/GPU 두 벌 빌드**로 간다.

### 다음 할 일

- [ ] PR #131 제목·본문 보강 — "배포 경로 하드닝" 이 모호. 엔트리포인트 항목 설명 확장,
      "관측 접속정보" → `LANGFUSE_*` 구체화, 예외 원문 노출의 잔존 범위 명시
- [ ] 임베딩 모델 이미지 번들링 (CPU/GPU 두 벌) + 배포 문서의 다운로드 안내 정정
- [ ] `requirements.txt` 3분할 + Dockerfile `TORCH_VARIANT` ARG
- [ ] `chromadb` 제거 — Nuitka 가 `vanna/legacy/chromadb` 컴파일 시 경고 확인 필요
- [ ] 빌드 전용 도구를 런타임 venv 에서 분리
- [ ] `orchestrator.py` 의 모델명·device 하드코딩 → config 사용
- [ ] `sites/*/env.overlay` 를 `.gitignore` 에 추가 — 시크릿이 든 채 untracked 로 방치됨
- [ ] `SOURCE_REPOS_TOKEN` 등록 또는 패키징 워크플로의 빌드 경로 제거
- [ ] pigz 로컬 판정/원격 실행 불일치 (`--remote-compress`)
- [ ] 예외 원문 노출 잔존 — `bookmarks/routes.py:485,515,583`, `auth` 5곳, `group_admin` 5곳
- [ ] 웹 타입 오류 11건 (`components/bi-slide/*`) — `ignoreBuildErrors: true` 로 가려져 있음
- [ ] 빌드 서버에 `pigz` 설치

## 2026-08-10 — 라이선스 위조 위협모델 + 부트스트랩 난독화

- [x] 라이선스 위조 가능성 분석 — HMAC 대칭키(`DNA_LICENSE_SECRET`)라 시크릿 쥔 고객이 자가 서명 가능. 소스 은닉과 무관 → [[knowledge/patterns/symmetric-mac-verifier-can-forge]]
- [x] `license.key` 최신 스키마(`hostname`+`machine_id`)로 재발급
- [x] 검증 출처 규명 — 런타임은 `config/license.json`만 봄, 키 파일은 `not_activated`일 때만 부트스트랩 → [[issues/license-key-file-not-reapplied-when-config-present]]
- [x] refactor: `main.py`(1592줄) → `src/dna/app/` 패키지 분리, `main.py`는 shim. Nuitka 난독화 범위 포함 → [[decisions/033-bootstrap-logic-into-compiled-package]]
- [x] PR #138 생성 (chore/dockerfile-permission-hardening → main)
- [ ] (권고) 라이선스 서명 HMAC → Ed25519 비대칭 전환 검토
- [ ] (권고) 갱신 footgun 완화 — 자동활성화 게이트를 "유효 active 아니면 키파일 재검토"로 확장
- [ ] `get_status()`가 구 스키마 캐시의 `ValidationError`를 못 잡아 기동 크래시 → `invalid` 폴백 처리
- [ ] PR #138 리뷰·머지

## 2026-08-13 — 설정 스펙 검증 + 설정/RAG 문서 정본화 (`feat/config`)

- [x] `tool_access`·`ui_features` 설정을 키 기반 객체 구조로 전환, `ui_features` defaults 분리
- [x] 기동 시 설정 파일 검증 추가 — `defaults/*.json` 을 스펙으로 `config/*.json` 대조, 없는 키·타입 불일치는 기동 중단, 모르는 키는 경고 → [[decisions/034-defaults-as-config-validation-spec]]
- [x] 메타 키를 `_` 접두 사이드카로 통일 (`_required`/`_type`/`_item`), 회귀 테스트 61건
- [x] `collection_runner` 를 설정 API 노출 대상에서 제외 (기본값 전용 섹션)
- [x] defaults 스펙 린터 `scripts/check_default_config.py` — 짝 없는 사이드카·`_type` 불일치·`_item` 누락 등 검출, 배포 이미지에서는 제외 → [[knowledge/patterns/defaults-file-as-validation-spec]]
- [x] fix: `sql_guard.max_query_length` 가 `SQLInspector` 에 전달되지 않던 문제 → [[issues/sql-guard-max-query-length-not-passed-to-inspector]]
- [x] fix: 설정 리로드 시 마스킹 그룹 액션이 파일 사본으로 되돌아가던 문제 → [[issues/masking-group-action-lost-on-settings-reload]]
- [x] fix: 마스킹 기본 그룹 액션 폴백 `none` → `mask` (fail-closed)
- [x] docs: 설정 문서 재편 — `server-settings-design` 1251→464줄, `settings-ui-design` 867→726줄, RAG 파이프라인은 `rag-architecture` 로 통합. 값 목록·엔드포인트 표는 정본 하나만 두고 링크
- [x] PR 생성 — 서버 [#140](https://github.com/DnA-Platform-Development-Team/dna-sql-agent/pull/140), 웹 [#82](https://github.com/DnA-Platform-Development-Team/dna-sql-agent-web/pull/82)
- [x] `origin/main` 병합 (질의 명확화 기능 26커밋) — `tool_access` 구조 충돌을 키 기반으로 해소
- [x] 설정 API 관리자 전용화 · 설정 정의를 `API_SECTIONS` 하나로 통합
- [ ] PR #140 리뷰·머지 (웹 #82 는 서버 머지 후)
- [ ] `masking.json` 의 `strategies.*.columns` 8곳에 `_item` 추가 (린터 WARN 8건)
- [ ] `check_default_config.py` CI 연결 여부 결정
- [ ] `settings-ui-design.md` Tab 6(Foundation/llm) 이 폐기된 섹션 기준 — 화면 실제 구성과 대조 필요
- [x] 도구 권한 fail-open 정리 — 빈 목록을 거부로 뒤집고 전 도구 전환 시딩 → [[issues/tool-permission-revoke-all-becomes-allow-all]]
- [ ] `origin/main` 병합(ac6d29b) 후속 — `docs/clarification-design.md` 의 "tool_access 에서 접근 그룹 관리" 서술이 우리 구조와 어긋남

## 2026-08-14 — 도구 권한 fail-open 정리 + 설정 미반영 표시 (`fix/tool-access-apply`)

- [x] fix: 빈 허용 그룹을 거부로 변경 — 판정 3벌(실행·스키마 노출·결과 출력)을 `registry.has_tool_access()` 로 통합
- [x] fix: 권한 해제가 반영되지 않던 문제 — `_apply_tool_permissions()` 를 레지스트리 전체 순회로, 미등록 DB 키는 경고
- [x] feat: 도구 on/off 를 재기동 없이 설정 적용으로 반영 — `unregister_local_tool()` + `sync_registered_tools()` 를 hot_reload 에 편입 (`vector_search` 내려가면 `clarify_request` 도 함께)
- [x] fix: 최초 설치에서 도구 권한이 시딩되지 않던 문제 — 설정 파일 생성 전에 판단해 전 도구에 표식, 추측 기반 `seed_from_json_if_empty()` 삭제
- [x] fix: estimator 설정이 실행에 반영되지 않던 문제 — `apply_config()` 추가, pool 생성·호출 양쪽 적용
- [x] feat: 반영되지 않은 설정 조회 API — `ApplyMode` 선언 + `GET /api/v1/settings/pending`
- [x] feat: 설정 화면 헤더에 미반영 배너 (웹) — 라벨은 설정 섹션 헤더와 일치, 재시작이 필요하면 문구 하나에 목록만 합침
- [x] fix: 기동 중 설정 파일 쓰기가 미반영으로 잡히던 문제 — `mark_started()` 로 기준 시각 이동
- [x] fix: 금액 `$` 가 수식으로 렌더링되던 문제 (웹) — `singleDollarTextMath: false`
- [x] docs: `server-settings-design.md` §9 정본 표를 실제 동작에 맞춰 정정, 상단 다이어그램 중복 목록 제거
- [x] ADR: [[decisions/035-empty-access-groups-means-deny]], [[decisions/036-apply-mode-declaration-and-pending-notice]]
- [ ] 테스트가 `src/vanna` 를 보도록 경로 정리 — 정리하면 `test_tool_permissions.py` 11건 실패 (옛 동작 단언 2, 메시지 문구 3, transform_args 6)
- [ ] `origin/main` 최신화 후 PR — `registry.py`·`agent.py` 충돌 가능
- [ ] DB에 남은 미등록 도구 권한 6건 처리 방침 (일부러 남긴 것이라 삭제 보류)
- [ ] 권한 적용 실패 시 기동 중단 여부 결정 — 거부 기준이라 DB 장애 시 도구가 전부 막힘
- [ ] `RELOAD` 선언 섹션이 실제 `hot_reload()` 단계에 있는지 검사 (`scripts/check_default_config.py` 확장)

## 2026-08-20 — 차트 다중 시리즈 + 엔진별 지원 타입 정리 (`feat/chart-generate`)

- [x] feat: `y` 에 쉼표로 여러 컬럼을 주면 다중 시리즈로 표시 — 새 타입 대신 기존 `bar`/`line`/`area` 에 얹음, 컬럼 해석은 `chart_columns.resolve_columns()` 하나로 세 생성기 공유
- [x] feat: devextreme 노출 목록에 `area`/`stackedBar`/`stackedArea`/`spline` 추가 — 생성기는 처음부터 매핑했는데 목록에 없어 LLM 이 고를 수 없던 상태
- [x] fix: 쉼표 목록이 렌더러까지 전달되던 버그 — `bar`/`line` 외 분기(기본값 `auto`·scatter·pie·histogram·heatmap)가 `"A,B"` 를 컬럼명으로 넘겨 예외, echarts pie/scatter/heatmap 도 동일 보완
- [x] refactor: 도구 설명을 엔진 지원 타입으로 조립 — `CHART_TYPE_AXIS_HINTS` 테이블에서 `x`/`y`/`value`/`color` 설명 생성, 같은 문구는 렌더링 단계에서 합침
- [x] refactor: 지원 밖 타입은 `Literal` 검증 대신 사유·선택지를 담은 오류로 반환 — 도구가 근사 타입으로 대신 그리지 않음
- [x] feat: plotly `combo` 추가 — `y` 주축 막대, `value` 보조축 선
- [x] style(웹): 드롭다운 focus 시 글자·아이콘 색 고정, 항목 4종 반응 통일, 모서리 6px
- [x] fix(웹): 다크모드 `--popover` 가 `--background` 보다 어두워 메뉴가 떠 보이지 않던 문제
- [x] docs(웹): `dual-axis-chart-design.md` → `combo-chart-design.md` 현행 기준 재작성, `CLAUDE.md` 에 PR 양식 절 추가(백엔드와 동일화)
- [x] ADR: [[decisions/037-engine-capability-gating-in-tool-schema]], [[decisions/038-chart-shape-by-type-not-by-argument]]
- [x] PR: 서버 #154 · 웹 #88 머지

## 2026-08-25 — 폐쇄망 지도 타일 런타임 설정 (`feat/offline-map-tiles`)

- [x] 폐쇄망 미지원 항목 전수조사(백엔드·웹) — 런타임 차단 4건 확인: Plotly CDN, 지도 타일, Office.js, Vercel Analytics
- [x] 백엔드 제품 코드에 CDN 하드코딩 없음 확인 — GeoJSON 자체 서빙, vanna legacy(ask.vanna.ai 등)는 죽은 코드, 텔레메트리 없음
- [x] feat(웹): `/map-config` 라우트가 요청 시점 env 를 읽어 타일 설정을 내려주도록 전환 — 이미지 재빌드 없이 `.env` 만으로 사내 타일 서버 전환
- [x] feat(웹): 지정한 모드만 배경 선택 버튼에 노출, 남은 모드가 하나면 버튼 감춤. 미지정 시 종전대로 공개 서버 사용
- [x] refactor(웹): 변수를 화면 용어에 맞춰 셋으로 확정 — `MAP_TILE_URL` / `MAP_TILE_URL_SIMPLE` / `MAP_TILE_URL_SIMPLE_DARK`
- [x] refactor(웹): 화면에서 고를 수 없던 프리셋(Voyager·위성·지형)과 미사용 라벨 타일·타입 정리
- [x] docs(웹): `docs/offline-map-tiles.md` 추가
- [x] feat(deploy): compose 가 타일 env 를 web 컨테이너로 전달, `.env.template` 지도 배경 절 추가
- [x] docs(deploy): `README.txt` `[지도 배경]` 절 · `INSTALL.txt` `.env` 확인 항목 추가
- [x] ADR: [[decisions/039-runtime-config-via-server-route]]
- [x] 배포 패키지를 맥에서 기동해 검증 — 백엔드 `/health` 200, 화면 접속 확인
- [x] PR: 웹 #89 (deploy 는 커밋만, PR 미생성)

### 이 과정에서 드러난 것 (미해결)

- [ ] arm64 맥에서 웹 도커 빌드 실패 — `Dockerfile:15` 의 x64 네이티브 패키지 하드코딩. 지금은 `npm ci` 만으로 musl 이 들어오므로 그 줄 삭제로 해결
      → [[projects/dna-sql-agent-web/issues/docker-arm64-build-hardcoded-x64-native-binary]]
- [ ] 백엔드 이미지 10.4GB — `models/` 가 `.dockerignore` 에 없어 2.2GB 가 구워짐(compose 가 어차피 마운트) + CUDA torch 의 `nvidia/` 2.8GB
      → [[issues/backend-image-size-models-baked-and-cuda-torch]]
- [x] 라이선스 머신 바인딩 규명 — Linux 경로는 hostname 을 보지 않고 `machine_id` + (`cpu_model` 또는 `mem_total`) 로 판정
      → [[issues/license-linux-binding-ignores-hostname]]
- [ ] 저장소 remote URL 에 PAT 평문 노출 — 폐기·교체 필요
- [ ] 차트 다중 시리즈·combo 도입분(PR #154) 코드 리뷰 지적 5건 — 기록만, 재현·수정 미착수

### 다음

- [ ] deploy 저장소 PR 생성
- [ ] Plotly CDN 제거 — `plotly.js` 가 의존성에 있으나 import 하지 않아 번들에 없음. 폐쇄망에서 차트가 `Loading chart...` 로 멈춤
- [ ] Office.js · Vercel Analytics 스크립트 제거
- [ ] 배포 이미지에 `HF_HUB_OFFLINE=1` 검토

## 2026-09-16 — 지도 배경 CARTO 워터마크 대응 (`fix/map-simple-tiles`)

- [x] 원인 규명 — 환경변수 추가가 아니라 **CARTO 의 무료 베이스맵 정책 변경**. 키 없는 요청에 `API KEY REQUIRED` 를 인쇄한 타일을 HTTP 200 으로 반환
- [x] 대안 실측 비교 — CARTO 키 발급(상업적 사용은 엔터프라이즈 논의 대상·키 노출) / OpenFreeMap 벡터(maplibre gzip 293KB·WebGL 필수·지도 다중 표시 시 컨텍스트 상한) / Esri 래스터
- [x] ADR: [[decisions/040-keyless-raster-basemap]]
- [x] fix(웹): 심플 모드 기본 타일을 Esri 회색 캔버스로 교체, `Tile` 에 `labelUrl`·`maxNativeZoom` 추가
- [x] fix(웹): 지명 라벨 타일 레이어 추가 — `map-labels` pane(z-index 250, 클릭 통과), 배경 위·데이터 아래
- [x] fix(웹): 한국 타일 커버리지(밝은 z13·어두운 z16)를 `maxNativeZoom` 으로 흡수 — 그 이상 확대 시 "Map data not yet available" 회피
- [x] style(웹): 출처 문구를 `© Esri | © OpenStreetMap` 두 링크로 축약 (원문 전체는 모드 토글과 겹침)
- [x] docs(웹): 가이드의 기본 제공처 표기를 Esri 로 정정
- [x] 검증 — 빌드 통과·지도 파일 타입 오류 0건, `/map-config` env 조합 4가지 확인, 어두운 테마 실화면에서 워터마크 없음·로드 실패 0·줌 상한 동작 확인
- [x] 이슈: [[issues/carto-basemap-api-key-watermark]] / 범용: [[knowledge/tools/keyless-map-tile-providers]]
- [x] PR: 웹 #90 (커밋 3개)

### 이 과정에서 드러난 것

- [ ] CI 워크플로 3개(dev·linko·mobigen)에 **env·시크릿 주입 지점이 전혀 없음** — `docker run` 에 `-e` 도 `--env-file` 도 없어 런타임 설정 통로가 이미지에 구워지는 `.env.production` 뿐. 설치 패키지(compose)만 env 로 바꿀 수 있음
- [ ] 가이드에 "사내 타일에는 지명이 그림에 포함돼 있어야 한다" 설명 없음 — 이번엔 추가하지 않기로 함

### 다음

- [ ] PR #90 머지 후 `dna-sql-agent-web_dev.yml` 수동 실행으로 dev 반영, 이어서 linko·mobigen
- [ ] 밝은 테마 z13 이상 화면·기본 모드 전환 육안 확인 (브라우저 자동화 실패로 미확인)
- [ ] 설치 패키지 고객사는 이미지 재배포 필요 — 배포 시점 결정

## 2026-09-22 — 슬래시 커맨드 (`feat/slash-command`)

- [x] 현재 구조 분석 — 커맨드가 `DefaultWorkflowHandler` 조건문에 하드코딩, 별칭이 일반 질문을 가로채고 미등록 커맨드는 LLM으로 넘어가는 상태
- [x] 설계 문서 `docs/design/chat/slash-command-design.md` 작성·구현과 동기화 (모순 점검 포함)
- [x] feat(백엔드): `slash_commands` 테이블·기본 커맨드 4종, 해석·권한·실행 서비스, 조회 API·관리자 CRUD API
- [x] feat(백엔드): 커맨드 턴 이력 저장, 스킬 스냅샷과 LLM 직전 블록 펼침, 대화 요약·메모리 검색어 처리, 커맨드 감사 이벤트
- [x] feat(백엔드): `/help`(예시 질문 버튼)·`/status`(도구 설정 기준 표)·`/memories`(목록 컴포넌트)·`/delete` 한글화
- [x] feat(웹): 입력창 커맨드 목록(문장 중간 `/`, 맨 앞 이동, 일치 없으면 닫기), `item_list` 표시, 버튼 분류·새로고침 순서 보정, 후속 질문 `→` 목록
- [x] fix: 답변 HTML 태그 금지 규칙, 후속 질문 템플릿 중괄호 자리표시자 제거
- [x] ADR: [[decisions/041-slash-commands-db-registry]], [[decisions/042-skill-turn-snapshot-and-llm-expansion]], [[decisions/043-command-result-dedicated-component]]
- [x] 이슈: [[issues/workflow-short-circuit-components-attach-to-previous-answer]] / 범용: [[knowledge/prompting/llm-copies-template-placeholders]]
- [x] PR: 백엔드 #162, 웹 #93 (테스트 백엔드 85건·웹 8건 통과)

### 다음

- [x] PR #162·#93 머지
- [ ] 시스템 범위가 빈 대화에서 `/memories`가 전체 시스템 메모리를 보여 주는 원인 추적 (삭제 오조작 위험)
- [ ] 후속 질문이 "후속 질문 문장"을 그대로 베끼는지 관찰 — 재발 시 응답 정리 미들웨어에서 링크 글자 정리
- [x] SQL 예제 화면 스타일 stash 복원 (`style/sql-example-ui`) — SQL 하이라이트는 공통 `SqlHighlightStyle` 컴포넌트로 해결
- [ ] 로컬 테스트 커맨드 `admin-guide`·`data-tour` 정리 여부 결정

## 2026-09-22 — SQL 예제 AI 생성 수정, 북마크 등록 404·해제 보류 (`fix/bookmark-component-row`)

- [x] fix(백엔드): task 모드 SQL 예제 AI 생성 러너가 설정된 작업 테이블(`sql_collection_jobs_v2`)을 조회하도록 수정 — `fix/collection-task-job-table` `7be2643`
- [x] 원인 규명: AI 생성 0건은 대상 DB 쿼리 이력 미설정(`pg_stat_statements` 라이브러리 미로드) → [[knowledge/troubleshooting/sql-history-collection-prerequisites]]
- [x] style(웹): SQL 예제 수정 창 상태 선택을 공통 `RadioGroup`으로 (`style/sql-example-ui` `7acfd93`)
- [x] fix: 차트 북마크 404 — 서버가 컴포넌트를 담은 실제 행으로 보정, 웹은 단계별 저장 행 id 유지 → [[issues/bookmark-component-row-mismatch-404]]
- [x] feat: 북마크 페이지 해제 보류·상단 저장/되돌리기·저장하지 않고 나갈 때 확인 → [[decisions/044-bookmark-page-deferred-remove]]
- [x] feat: 북마크 목록·참조 API에 사용 중인 대시보드 정보, 북마크 페이지 카드 안내·채팅 화면 확인창(대시보드 포함 시에만)
- [x] PR: 백엔드 #163, 웹 #94 (백엔드 북마크 테스트 15건 통과)

### 다음

- [ ] PR #163·#94 리뷰·머지
- [ ] `fix/collection-task-job-table`(`7be2643`) PR 생성
- [ ] 수집기가 쿼리 이력 조회 실패를 로그로만 남겨 "0건 완료"로 보이는 문제 — 작업 오류 표시 여부 결정
- [ ] Postgres 수집기의 `스키마명.` 포함 필터로 스키마 없이 쓴 쿼리가 제외되는 문제 검토
- [ ] SQL 예제 스타일(`style/sql-example-ui`) 화면 확인 후 항목별 커밋·PR

## 블로커

_(없음)_

## 메모

- 미팅: [[meetings/2026-05-13 SQL Agent 검토 회의 (실장님 제작 버전)|2026-05-13 SQL Agent 검토 회의 (실장님 제작 버전)]]
- 미팅: [[projects/dna-sql-agent/meetings/2026-05-18 활용 방안 및 제품명 결정]]
- 미팅: [[projects/dna-sql-agent/meetings/2026-05-26 벡터 연관관계 추론 및 SQL 리버스 엔지니어링 검토]]
- 미팅: [[projects/dna-sql-agent/meetings/2026-07-28 환경설정, 관리자기능, 권한, 라이선스 정책 검토]]
- 미팅: [[projects/dna-sql-agent/meetings/2026-08-06 다답 일정 및 사업 현황 정리]]
- PPT 추가기능 동작 흐름 (실장님 설명):
  1. LLM에게 비율 상의 PPT 컴포넌트·내용 생성 요청
  2. LLM이 JSON 형식으로 슬라이드 구조 반환
  3. 웹에서 PPT 사이즈 기준으로 정확한 위치 계산 후 렌더링
  4. 스타일 템플릿은 웹 소스에 지정된 템플릿 사용
