---
type: index
updated: 2026-07-16
---

# my-wiki — Index

이 위키의 전체 페이지 카탈로그. LLM이 질의 시 이 파일을 먼저 읽고 관련 페이지를 찾는다.

## 프로젝트

| 프로젝트 | 상태 | 스택 | 마지막 갱신 |
|---------|------|------|-----------|
| [[projects/kacportal/overview\|kacportal]] | active | java, spring, egovframe, oracle, altibase, tomcat | 2026-07-15 |
| [[projects/kac-idp-noti/overview\|kac-idp-noti]] | active | java, spring, kafka, hibernate, tibero, altibase, mysql, docker | 2026-04-21 |
| [[projects/dna-sql-agent/overview\|dna-sql-agent]] | active | python, fastapi, vanna, vllm, ollama, oracle, postgres, qdrant, docker | 2026-07-16 |
| [[projects/dna-sql-agent-web/overview\|dna-sql-agent-web]] | active | nextjs, typescript, tailwindcss, shadcn-ui, plotly, docker | 2026-07-16 |

## Knowledge Base

### 도구 & 기술
- [[knowledge/tools/echarts-tooltip-json-patterns|ECharts Tooltip — JSON 환경 포맷터 패턴 ({b}, pre-line, visualMap)]]

### 패턴
- [[knowledge/patterns/static-html-harness-bypass-missing-db|정적 HTML 하니스로 DB/백엔드 없이 프론트 로직만 실제 라이브러리로 검증하기]]
- [[knowledge/patterns/sse-post-completion-patch|SSE 완료 후 최소 패치 패턴 — 스트리밍 state 보존]]
- [[knowledge/patterns/postgres-lateral-latest-row-per-group|PostgreSQL LATERAL JOIN — 그룹별 최신 1건 조회]]
- [[knowledge/patterns/optimistic-update-table-toggle|테이블 토글 셀 옵티미스틱 업데이트 — Set 기반 롤백 패턴]]
- [[knowledge/patterns/refresh-token-rotation-axios-interceptor|Refresh Token Rotation — axios 401 인터셉터 + 큐 패턴]]
- [[knowledge/patterns/401-interceptor-queue-pattern|401 인터셉터 큐 패턴 — native fetch refresh token 자동 갱신]]
- [[knowledge/patterns/async-state-watch-with-useEffect|비동기 state 감지 — pendingKey + useEffect 패턴]]
- [[knowledge/patterns/sse-cancel-user-message-save|SSE 스트리밍 중단 시 사용자 메시지 저장 — try/finally + stream_completed + asyncio.create_task]]
- [[knowledge/patterns/request-token-stale-response-guard|요청 토큰(reqRef)으로 stale 비동기 응답 무시 — 다이얼로그/탭 전환 race 방지]]
- [[knowledge/patterns/react-grid-drag-memoize-heavy-children|드래그앤드롭 그리드 무거운 자식 리렌더 최적화 — React.memo + will-change + props 참조 안정성]]
- [[knowledge/patterns/reverify-role-on-privileged-route-entry|권한 라우트 진입 시 서버 재검증 — 로그인 시점 캐시만 믿지 않기]]

### 트러블슈팅
- [[knowledge/troubleshooting/cargo-maven3-plugin-property-vs-properties-syntax|cargo-maven3-plugin "Cannot find 'property' in class Configuration" — <property> 단수 문법 대신 <properties> Map 바인딩 필요]]
- [[projects/kacportal/issues/smdevc-smart-statistics-excel-download-sheetname-missing|kacportal: 엑셀 다운로드 버튼 무반응 — xl.sheetName 누락으로 makeXl() TypeError]]
- [[projects/kacportal/issues/local-tomcat-cargo-run-setup-broken|kacportal: 로컬 Tomcat(cargo-maven3-plugin) 실행 전면 실패 — pom.xml 문법 오류 + war 패키징 누락 + Altibase 드라이버 비활성화 3단 연쇄]]
- [[knowledge/troubleshooting/overflow-y-auto-focus-ring-clip|overflow-y-auto — 자식 input focus ring 좌측 클리핑 (pl-[3px] 해결)]]
- [[knowledge/troubleshooting/spring-url-double-encoding|Spring — 외부 API URL 더블 인코딩/프리픽스 방지]]
- [[knowledge/troubleshooting/message-rendering-heuristic-pitfall|메시지 렌더링 휴리스틱의 함정 — 단순 텍스트 드랍 안티패턴]]
- [[knowledge/troubleshooting/sticky-column-offset-mismatch|HTML Table sticky 컬럼 두 번째 열 left 오프셋 틀어짐 — w+min-w+max-w 고정]]
- [[knowledge/troubleshooting/shadcn-table-sticky-header-overflow-wrapper|shadcn/ui Table sticky 헤더 미동작 — overflow 래퍼가 스크롤 기준 가로챔, plain table 교체]]
- [[projects/dna-sql-agent/issues/sse-middleware-str-bytes-type-error|Starlette SSE 미들웨어 — str yield 시 TypeError (bytes 인코딩 필수)]]
- [[projects/dna-sql-agent-web/issues/bookmark-soft-remove-rebookmark|React useMemo ref 의존성 함정 — soft remove + in-place rebookmark]]
- [[projects/dna-sql-agent/issues/echarts-heatmap-duplicate-cell|ECharts heatmap — 같은 셀 중복 매핑 시 합산 집계 필요]]
- [[projects/dna-sql-agent/issues/echarts-sankey-dag-cycle|ECharts Sankey DAG 사이클 오류 — iterative DFS back-edge 제거]]
- [[projects/dna-sql-agent/issues/echarts-sankey-oracle-decimal-tier-detection|ECharts Sankey Oracle Decimal 티어 컬럼 오감지 — coerce_numeric=False]]
- [[projects/dna-sql-agent/issues/bookmark-query-sql-limit-not-injected|북마크 query_sql LIMIT 미반영 — tool_calls는 실행 전 저장, create_bookmark에서 _inject_limit]]
- [[projects/dna-sql-agent/issues/settings-reset-not-restoring-saved|에이전트 설정 리셋이 저장값 복원 안 됨 — ctx.reset 공장초기화 + 권한 카드 resetRef 미배선]]
- [[projects/dna-sql-agent/issues/bookmark-refresh-map-type-lost|북마크/위젯 새로고침 시 지도→바 차트 — render_bookmark에 map 분기 부재]]
- [[projects/dna-sql-agent/issues/dashboard-delete-setstate-in-render|대시보드 삭제 setState-in-render — 업데이터 내부 부수효과(router.push) 금지]]
- [[projects/dna-sql-agent/issues/flowmap-legend-color-equals-from-label|flow map 범례 누락 — color==from_label일 때 display_cols 제외 회귀]]
- [[projects/dna-sql-agent/issues/bookmark-display-missing-on-chat-entry|채팅 북마크 표시 누락 — 진입 시 미로드 + 페이지네이션 → 대화별 refs 조회]]
- [[projects/dna-sql-agent/issues/dashboard-account-switch-stale-state|로그아웃 후 재로그인 시 대시보드/북마크 상태 잔존 → 재로드 안 됨 (hasLoadedRef 가드 함정)]]
- [[projects/dna-sql-agent/issues/dashboard-transition-height-chain-flicker|대시보드 전환 시 화면 깜빡임 + 스크롤 불가 (불필요한 리마운트 + h-full 체인 끊김)]]
- [[knowledge/troubleshooting/flex-height-chain-broken-by-missing-h-full|overflow-y-auto가 안 먹힘 — 스크롤이 아니라 조상 h-full 누락으로 클리핑되는 것]]
- [[knowledge/troubleshooting/auth-headers-must-not-delete-localstorage|인증 헬퍼 함수에서 localStorage 삭제하면 refresh token까지 소멸]]
- [[knowledge/troubleshooting/json-nan-serialization|JavaScript: NaN이 JSON.stringify 시 null로 직렬화 — 인증 토큰 만료 계산 주의]]
- [[knowledge/troubleshooting/fitted-chart-height-borderbox-chrome|고정 높이 셀 안 차트 짤림 — border-box 카드 테두리까지 크롬 차감]]
- [[knowledge/troubleshooting/docker-custom-network-iptables-forward|Docker 커스텀 네트워크 컨테이너 간 통신 불가 — iptables FORWARD DROP 및 --network host 대안]]
- [[knowledge/troubleshooting/docker-publish-localhost-only|Docker --publish 127.0.0.1:port:port — 외부 직접 접근 차단 (nginx 뒤 앱 컨테이너 보호)]]
- [[knowledge/troubleshooting/pip-install-into-wrong-env-venv-vs-pyenv|Python — pip install이 .venv 아닌 pyenv 전역에 설치되는 문제 (ModuleNotFoundError)]]
- [[knowledge/troubleshooting/pandas-to-json-datetime-epoch|pandas df.to_json()이 datetime을 epoch 밀리초(숫자)로 직렬화 — date_format="iso"]]
- [[projects/dna-sql-agent/issues/conversation-title-empty-string-sentinel-broken-by-default|새 대화 제목 빈 문자열 센티널이 기본값 변경으로 깨짐 — 첫 메시지 자동 갱신 불가]]
- [[projects/dna-sql-agent/issues/systems-list-api-slow-n-plus-one-and-heavy-json-column|시스템 목록 API 응답 지연 — N+1 쿼리 + 대용량 JSON 컬럼(table_relation_info) 전체 조회]]
- [[knowledge/troubleshooting/react-controlled-number-input-same-numeric-value-no-dom-update|React 컨트롤드 number input — 같은 숫자값이면 DOM 미갱신 (ref로 직접 커밋 필요)]]
- [[projects/dna-sql-agent/decisions/010-sql-guard-schema-qualified-block|SQL Guard — schema.table 형식 차단으로 스키마별 동명 테이블 구분]]
- [[projects/dna-sql-agent/decisions/011-guardrail-block-no-retry-strategy|SQL Guard — 가드레일 차단 시 LLM 재시도 방지 (result_for_llm 지시 방식)]]
- [[projects/dna-sql-agent/decisions/012-masking-group-actions-db-migration|마스킹 그룹 액션 DB 이관 — masking.json groups 제거, 초기값 없음]]
- [[projects/dna-sql-agent/decisions/015-bookmark-dashboard-architecture|북마크-대시보드 아키텍처 — SQL 추출 시점 + 스냅샷/캐시 전략]]
- [[projects/dna-sql-agent/decisions/016-dashboard-widget-sizing-model|대시보드 위젯 크기 모델 — 고정 프리셋 + 반응형 컬럼 + 비례 높이]]
- [[projects/dna-sql-agent/decisions/017-llm-connection-immediate-save|LLM 연결 관리는 즉시 저장으로 통일 — dirty-save 폐기 (foundation 탭 안내 문구)]]
- [[projects/dna-sql-agent/decisions/018-geojson-map-visualization|GeoJSON 지도 시각화 — 임베드 스냅샷 + chart_type='map' 3형태(점/지명/흐름), 필드 LLM 선정]]
- [[projects/dna-sql-agent/decisions/019-flowmap-list-grouping|지도 데이터 목록 from==to 기준 분류·from/id 그룹핑 (점/흐름 분리, 접기)]]
- [[projects/dna-sql-agent/decisions/020-context-sensitive-sidebar-swap|라우트에 따라 사이드바 컴포넌트 자체를 교체 (숨김 대신 스왑) — ConversationList ↔ DashboardPanel]]
- [[projects/dna-sql-agent/decisions/021-admin-list-server-side-pagination|관리자 목록 서버사이드 페이징 — 페이징 API + 무페이징 roster API 병행]]
- [[projects/dna-sql-agent/decisions/022-relative-date-dynamic-sql-and-fixed-date-detection|상대 날짜는 DB 동적 함수로 생성 + 대시보드 고정 날짜 감지·경고 병행]]
- [[projects/dna-sql-agent/decisions/023-group-admin-role-and-permission-model|그룹 관리자 역할과 이중 레이어 권한 모델 — 그룹↔시스템 매핑(상한선) vs 사용자 권한(실제판정), DB 조회 기반 인가]]
- [[projects/dna-sql-agent/issues/map-point-duplicate-selection-same-coords-and-properties|지도 point 좌표+속성 완전 동일 행 다중 선택 — 행 위치 기반 Feature.id 부여]]
- [[projects/dna-sql-agent/issues/dashboard-widget-stale-after-bookmark-deleted|북마크 삭제해도 열려있는 대시보드 위젯 안 사라짐 — activeId 불변 가드로 재조회 누락]]
- [[projects/dna-sql-agent/issues/dashboard-drag-drop-jank-heavy-widgets|대시보드 드래그·드롭 시 무거운 위젯 버벅임 — 리렌더 + GPU 레이어 미승격 + props 참조 불안정]]
- [[projects/dna-sql-agent-web/issues/group-admin-entry-point-missing|그룹 관리자 지정해도 관리자 페이지 진입 방법 없음 — 역할 캐시 미재검증 + 사이드바 진입 버튼 조건 누락]]
- [[projects/dna-sql-agent/decisions/026-group-admin-v0.9-refinements|그룹 관리자 정책 v0.9 — default_grant 자동 시딩, 권한 매트릭스 스코프 제한, 벌크 그룹 이동]]
- [[knowledge/troubleshooting/postgres-collate-korean-english-mixed-sort|PostgreSQL 한글/영문 혼용 정렬 깨짐 — COLLATE "und-x-icu"로 해결]]

### 패턴
- [[projects/dna-sql-agent-web/decisions/014-multi-server-nginx-reverse-proxy|다중 서버 배포 — nginx 리버스 프록시로 API URL 통일 (CORS 자동 해결)]]
- [[projects/dna-sql-agent-web/decisions/015-http-addin-nginx-28001|PPT 애드인 HTTP 지원 — nginx 28001 포트 프록시 (same-origin 유지)]]
- [[projects/dna-sql-agent-web/decisions/013-chart-palette-shared-constant|차트 공통 컬러 팔렛트 — 정적 상수 파일로 다중 엔진 통일 관리]]
- [[projects/dna-sql-agent-web/decisions/002-toast-pattern-jsx-icon|Toast JSX 아이콘 패턴 (shadcn)]]
- [[projects/dna-sql-agent-web/decisions/004-sse-done-event-message-id|SSE done 이벤트에서 필요 ID 직접 수신 (타이밍 레이스 제거)]]
- [[projects/dna-sql-agent-web/decisions/006-optimistic-update-permission-matrix|권한 매트릭스 셀 토글 옵티미스틱 업데이트]]

### 프롬프팅
- [[knowledge/prompting/effective-instructions|Claude Code 효과적 지시법]]

## 소스
- _(소스 추가 시 갱신)_
