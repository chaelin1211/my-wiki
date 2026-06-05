---
type: project-status
project: dna-sql-agent-web
updated: 2026-06-05
phase: active
---

# dna-sql-agent-web — 현재 상태

## 현재 단계

🔧 **개발 진행** 단계

## 완료된 것

- [x] 위키 프로젝트 폴더 생성
- [x] UI 작업 요소들 리스트업 (시각화 툴 수정 - chart 종류 추가 및 종류 선택 llm에게 일임)
- [x] CI/CD: `docker run --network host` 적용 (포트 포워딩 제거)
- [x] 시스템 선택 팝업 미출력 원인 파악 (시스템 1개 → 정상 동작 확인)
- [x] 마이페이지 구현 (프로필 조회, 비밀번호 변경) — PR #2 머지
- [x] 어드민 사이드바 `<a>` → `<Link>` 교체 (페이지 깜빡임 제거)
- [x] 어드민 레이아웃 인증 가드 추가 (비어드민 URL 직접 접근 차단)
- [x] 이전 대화 로드 시 단순 응답 메시지 누락 버그 수정 — PR #4
- [x] UI 수정: 접근 불가 메뉴 표시 제거 — 일반 사용자는 어드민 전체 접근 블락 처리
- [x] 대화 목록 이름 변경 (인라인 input, Enter/blur 저장, Escape 취소, 낙관적 업데이트)
- [x] 삭제 UX → DropdownMenu + AlertDialog 확인 모달로 교체
- [x] Toast JSX 아이콘 패턴 표준화 (성공 CheckCircle2, 오류 AlertTriangle)
- [x] `docs/ui-components-design.md` 작성 (Toast, AlertDialog, DropdownMenu)
- [x] `docs/toast-preview.html` 작성 (성공/오류 패턴 라이트·다크 미리보기)
- [x] destructive 토스트 배경/글씨 색 정비 (`bg-background`, `text-destructive`)
- [x] `/ui` 컴포넌트 미리보기 페이지 추가 (toast 3종 트리거 버튼)
- [x] feat/chat-list PR #8 생성 및 머지

## 완료된 것 (추가)

- [x] 대화 고정(pin) 기능 구현 및 PR #10 머지 (2026-05-21)
- [x] 북마크 기능 구현 (채팅 결과 카드 즐겨찾기) — feat/pin-chat 브랜치
- [x] UI 수정: light mode 채팅 목록 삭제 아이콘 안 보임 수정
  - 차트·표·아티팩트 컴포넌트 헤더에 북마크 토글
  - 사이드바 북마크 메뉴 버튼 (active 시 채워진 아이콘)
  - BookmarkView: 검색, 정렬, 카드 그리드, 인라인 제목 편집
  - flat prop 패턴으로 컴포넌트 재사용 (DataTable, ChartBlock, DevExtremeChartBlock)
  - patchBackendMessageIds 분리 (SSE steps 보존)
- [x] 북마크: API 정렬·검색 기능 추가 및 화면 연동
- [x] 북마크: 삭제 시 lazy delete (리로드 전까지 화면에 유지)
- [x] 북마크: 제목 수정 후 원복 기능 추가
- [x] 북마크: 반응형 — 2 rows→1 row 전환 최소 폭 넓히기
- [x] 북마크 열고 닫기 아이콘 방향 대화 목록과 통일
- [x] 북마크 카드 내 DevExtreme 차트 높이 조정 및 여백 처리
- [x] 북마크 생성일 기준 `component_created_at`으로 변경
- [x] SSE `done` 이벤트 신포맷 대응 (`message_id`/`conversation_id` 직접 수신)
- [x] 북마크 대기 중 스피너 표시 (차트·아티팩트 헤더)
- [x] DevExtreme 파이 차트 E2101 수정 (`series[0].type === 'pie'` 보정)
- [x] PR #14 생성 (fix/chat-bookmark)
- [x] 백엔드: SSE `done` 이벤트 신포맷 적용 (`message_id` 포함) — ADR-004
- [x] 북마크 화면 Plotly 차트 초기 미렌더 이슈 (SPA 네비게이션 resize 트리거)

## 완료된 것 (2026-05-27)

- [x] 전체 반응형 UI 개선 — `feat/responsive-ui` 브랜치 (미커밋 포함)
  - 대화 목록 사이드바: 52px 고정 strip, 모바일 전체화면 오버레이
  - 채팅 헤더 햄버거 제거, Office Add-in 감지 시 Settings/Admin 메뉴 숨김
  - 마이페이지·관리자 사이드바: 모바일 상단 가로 탭 + 오버플로 그라데이션
  - 관리자 SaveBanner 버튼 영역 스크롤 + 그라데이션
  - 탭 정렬·컨텐츠 너비 `max-w-5xl` 통일
  - 사용자·권한 검색 영역 반응형 (shadcn Select, flex-wrap)
  - 다크모드 Tabs 컨트라스트, ToggleGroup min-w, Tooltip bg 통일
- [x] 시스템 권한 매트릭스 UX 전면 재설계
  - 상단 Select 필터 제거, 행 클릭 → 상세 Dialog 팝업
  - 매트릭스 셀 옵티미스틱 업데이트 + 실패 시 롤백 — ADR-006
  - sticky 컬럼 고정 너비 수정 (w + min-w + max-w)
  - 권한 추가: 팝업 → 인라인 row (Select + tag input)
  - 매트릭스 깜빡임 수정 (loading 가드 Dialog 내부로 한정)

## 완료된 것 (2026-05-26)

- [x] HTTPS 설정 — 내부 CA + nginx 컨테이너 (GitHub Actions workflow에 nginx 스텝 추가) — ADR-005
- [x] API 서버 CORS 정책에 `https://<서버IP>` 추가 (HTTPS 전환 후 origin 변경 대응)
- [x] 대화 목록 last_message description 표시 (백엔드 API 명세 + 프론트 구현) — PR #16
- [x] 북마크 soft remove 후 재북마크 in-place 수정 (순서 유지, 리로드 없음)
- [x] 북마크 useMemo filter 버그 수정 (다중 soft remove 시 항목 사라지는 문제)
- [x] 채팅 헤더 시스템 뱃지 스타일 대화 목록과 통일 (getSystemColor pill)

## 완료된 것 (2026-05-29 추가)

- [x] 권한 매트릭스 시스템별 일괄 부여/해제 토글 버튼 (CheckSquare/Square, AlertDialog 확인)
- [x] Bulk grant/revoke API 연동 (`bulkGrantPermission`, `bulkRevokePermission`)
- [x] Bulk API 빈 배열 422 방지 (early return) 및 404 에러 코드 메시지 매핑
- [x] refresh 응답 `expires_in` 누락 시 `expiresAt: null` 버그 수정 (`?? 1800` fallback)
- [x] DB 관리 테이블 헤더/셀 중앙 정렬 및 뱃지·토글 컬럼 고정 너비
- [x] SQL 예제 상태 토글 낙관적 업데이트 (재조회 제거, 로컬 상태만 갱신)
- [x] SQL 예제 질의 컬럼 너비 확대(260px), 태그 컬럼 축소(100px)

## 완료된 것 (2026-05-29)

- [x] 권한 매트릭스에서 admin 그룹 제외 필터 제거 — admin도 매트릭스에 표시 및 권한 편집 가능
- [x] 그룹 배지 컬러 동적화 — `lib/group-color.ts` 통합, 해시 기반 팔레트 (admin 빨간색 고정) — PR #28
- [x] 권한 매트릭스 툴팁 → `title` 속성 교체 (툴팁이 인접 버튼 가리는 문제 해결)
- [x] 사용자 상태 토글 옵티미스틱 업데이트 — 즉시 반영, 실패 시 롤백, 불필요한 전체 재조회 제거
- [x] 사용자 목록 그룹/상태/설정 컬럼 너비 고정
- [x] 사용자 별 그룹 수정 다이얼로그 복구 (Pencil 버튼 + UserDialog) — PR #30
- [x] 그룹 배지 클릭 인라인 편집 (ChevronDown 아이콘, Select 드롭다운)
- [x] 그룹 멤버 관리 다이얼로그 신규 추가 (GroupMembersDialog, +/- 토글)
- [x] 그룹 생성 후 멤버 관리 다이얼로그 자동 오픈 (pendingNewGroupName + useEffect 패턴)
- [x] 기본(user) 그룹 멤버 제거 방지 + 툴팁 안내
- [x] 벌크 활성화/비활성화 버튼 동작 수정 (bulkToggle 시그니처 변경)
- [x] 그룹 뱃지 10자 말줄임 + hover 전체 이름 표시 (truncateGroupName 유틸)
- [x] 그룹명 32자 카운터, 중복 409 에러 인라인 표시
- [x] 테이블 정렬 통일, 리프레시 깜빡임 수정 (loading && data.length === 0 패턴)
- [x] 대화 목록 불러오기 갯수 증가
- [x] 다크모드 로그인 화면 아이콘 전구 빛 글로우 효과 추가 (amber animate-pulse, feat/favicon)
- [x] 로고 파일 분리 — favicon.png → logo.png (512×512 투명), apple-icon.png (180×180 보라색 배경) 신규 생성
- [x] 헤더 아이콘 Database 아이콘 → logo.png(40px)로 교체, AppHeader 아이콘 고정 영역 w-10 설정
- [x] layout.tsx 파비콘 설정 정리 — generator 제거, 올바른 아이콘 파일 참조 (favicon.svg + logo.png)
- [x] allowedDevOrigins 제거 (배포 환경에서 불필요)
- [x] 미사용 아이콘 파일 icons-unused/ 폴더로 정리

## 완료된 것 (2026-05-28)

- [x] refresh token 자동 갱신 — `lib/fetch-client.ts` 신규 (401 인터셉터 큐 패턴) — ADR-007
- [x] 로그인 시 `refresh_token` / `expires_in` 저장
- [x] 로그아웃 시 `POST /api/v1/auth/logout` 호출
- [x] 모든 API 파일 `fetchWithAuth()` 교체 (auth-api, chat-api, vanna-api, settings-api, sql-api)
- [x] `authHeaders()` 만료 시 localStorage 삭제 버그 수정 (refresh token 보존)
- [x] `use-auth.ts` 마운트 시 access token 만료여도 세션 유지
- [x] PR #21 머지 (feat/auth → main)
- [x] `@tanstack/react-virtual` 도입 — 메시지 가상 스크롤 (`chat-view.tsx`)
- [x] PR #22 머지 (fix/response-copy-button-error → main) — 개발서버 응답 복사 버튼 오류 수정
- [x] PR #23 머지 (feat/responsive-ui → main) — 반응형 UI 및 사용자 관리 개선
- [x] PR #19 머지 (feature/relation-info-ui → main) — Relation info generation UI
- [x] AppHeader 공통 컴포넌트 추출 — PPT 모드 마이페이지 버튼 숨김 공통 처리 — ADR-008
- [x] 북마크 화면에서 새 대화 생성 시 채팅 화면으로 자동 전환 (시스템 선택 완료 후)
- [x] PR #24 생성 (fix/bookmark-header-office-addin → main)
- [x] SessionExpiredError typed class 도입 — 세션 만료 콘솔 에러 제거 — ADR-009
- [x] PR #26 생성 (fix/session-expired-error-handling → main)
- [x] devextreme 24.2.x 유료 라이선스 확인 → ~24.1.17 고정 (24.2.x 업그레이드 보류)

## 완료된 것 (2026-06-01)

- [x] `expires_in` fallback `DEFAULT_EXPIRES_IN = 1800` 상수 추출 (매직 넘버 제거)
- [x] SQL 에디터 CodeMirror 교체 — auto-resize, 다크/라이트 테마, dangerouslySetInnerHTML 제거 — ADR-010
- [x] SQL 예제 다이얼로그 input 레이아웃 개선 (버튼 높이 통일, focus ring 클리핑 수정, 폰트 조정)
- [x] SQL 포맷팅 버튼 추가 (sql-formatter, 라벨 우측 배치)
- [x] DB 관리 상태 컬럼 태그 스타일 사용자 탭과 통일 및 너비 고정
- [x] PR #32 생성 (feat/admin-improvements → main)

## 완료된 것 (2026-06-02 — 색상 시스템 리뉴얼)

- [x] 전체 색상 시스템 교체: 보라 → 뉴트럴 그레이 + 오렌지 포인트(hue 42) — ADR-012, style/ui-spacing
- [x] 다크모드 가시성 개선: muted hover, border, sidebar-accent, ghost 버튼 opacity
- [x] 채팅창·북마크 배경 bg-background로 통일 (admin/mypage와 동일)
- [x] Switch thumb 다크모드 색상 개선 (unchecked→muted-foreground, checked→card)
- [x] Select 체크 아이콘 text-primary, Toggle outline border-border 적용
- [x] ToggleRow → shadcn Checkbox 교체 (settings/ui/shared.tsx)
- [x] 대화 목록 inner Button pointer-events-none (이중 hover 제거)
- [x] agent-tab space-y → flex gap 교체 (Tailwind v4 호환)
- [x] /ui 미리보기 페이지 보강: Input 상세 변형, Select, RadioGroup, ToggleGroup 추가
- [x] 브랜치명 fix/ui-spacing → style/ui-spacing

## 완료된 것 (2026-06-02)

- [x] SaveBanner 버튼 영역 스크롤 인디케이터 추가 (그라데이션 + 체브론) — feat/save-banner-scroll-indicator
- [x] ECharts 차트 엔진 프론트엔드 전 구현 — feat/echarts-chart-engine, PR #33
  - echarts@6.1.0, echarts-for-react@3.0.6 설치
  - EChartConfig 타입, chart_ec kind, ChartEngine 확장
  - SSE onChartEc 분기 연결
  - EChartsBlock 신규 생성 (다크모드, 동적 높이, 테이블 분기, grid 기본값 주입)
  - chat-message / chat-header / bookmark-view / agent-tab 연결
  - ADR-011: ECharts 프론트엔드 레이아웃 전략

## 완료된 것 (2026-06-04)

- [x] SVG 파비콘 재설계 — 오렌지 라운드 스퀘어 배경 + 로고 (ADR-012 색상 일관성)
- [x] Apple 아이콘(1024×1024) 및 logo.png(투명 배경) 교체
- [x] 다크모드 `--primary-foreground` 흰색 고정 (버튼 텍스트 가시성)
- [x] `--ring` → `var(--primary)` 통일 (포커스 링 색상 일관성)
- [x] outline 버튼/토글 hover border primary 적용
- [x] 라디오 버튼 다크모드 테두리 가시성 개선
- [x] ToggleGroup default 변형 border + 뮤트 배경, 이중 border 제거
- [x] `docs/ui-components-design.md` 디자인 미리보기 경로 안내 추가

## 완료된 것 (2026-06-05)

- [x] EChartsBlock 높이 동적 계산 개선 — Sankey 최대 열 노드 수 기반, 북마크 CSS scale-down
- [x] grid 기본값 추가 (containLabel, left/right 10px) — scatter 좌하단 여백 해결
- [x] gridBottom 조건 세분화 (visualMap 위치/표시 여부 확인)
- [x] resolvedOption backgroundColor/color 순서 수정
- [x] 차트 기본 높이 330 → 400 (ECharts/Plotly/DevExtreme 공통)
- [x] EChartsBlock 코드 정리 (헬퍼 함수 분리, renderChart 함수화)
- [x] docs/echarts-chart-design.md 4.7 섹션 현행화
- [x] feat/echarts-rendering-improvements 브랜치 커밋
- [x] 차트 타입 동적 추출 — 라이브러리별 지원 차트 종류를 공통 목록 대신 현재 라이브러리 기준으로 동적 추출하도록 변경
- [x] 버그 픽스: 대화 명 변경 후 다시 대화 시 제목 원복 되는 문제

## 진행 중

- [ ] 그래프 고도화 — 라이브러리별 시리즈 세팅 문제
- [ ] 버그 픽스: 대화 입력 후 답변 생성 중 다른 대화로 이동 시 이전 대화 저장 불완전
- [ ] 버그 픽스: 답변 생성 중단 시 이미 그려진 차트가 데이터에 저장 안 돼 북마크 불가 — 데이터 저장 시점 정리 또는 북마크 아이콘 제거 검토
- [ ] 버그 픽스: 새 대화 생성 시 서버 오류 처리

## 다음 할 일

- [ ] feat/echarts-rendering-improvements PR 생성 및 머지
- [ ] style/ui-spacing 브랜치 PR 생성 및 머지
- [ ] PR #33 머지 (ECharts)
- [ ] URL 라우팅 전환 (Next.js App Router) — 뒤로가기 지원, 반나절~하루 공수 예상, 별도 브랜치
- [ ] devextreme 라이선스 장기 플랜 검토 (유료 전환 or 대체 라이브러리)
- [ ] 북마크 기반 대시보드 기능 기획 — 북마크된 카드를 모아 커스텀 대시보드 뷰 구성 (활용도 향상)
- [ ] 권한 매트릭스 로딩 N+1 개선 — `loadAllPermissions`가 유저 N명 순차 API 호출 중. `Promise.all` 병렬화 또는 백엔드 일괄 조회 API 추가 검토
- [ ] 권한 취소 AlertDialog "취소" 버튼 문구 중복 검토
- [ ] 어드민 쪽 toast 한국어 + JSX 패턴으로 통일 (db-management/*, app/admin/*)
- [ ] Connections status 토글 깜빡임 수정 (옵티미스틱 업데이트)
- [ ] 백엔드 어드민 API 권한 체크 확인

## 블로커

_(없음)_

## 메모

- 시스템 선택 팝업: active 시스템 2개 이상일 때만 표시, 1개면 바로 생성 (설계 동작)
- 어드민 인증 가드: 클라이언트 사이드만 적용됨, 백엔드 API 권한 체크 별도 확인 필요
- Toast 표준 패턴: 성공=CheckCircle2(green), 오류=AlertTriangle(red) JSX 형식 — [[decisions/002-toast-pattern-jsx-icon]]
- 나중에 한번에 처리할 UI 개선 목록 (우선순위 낮음):
  1. 불필요한 리로드로 인한 서비스 매끄러움 감소 (system, connection 등 토글 시 깜빡임)
  2. system 토글 불가 상황 시 readonly 처리 및 안내 문구
  3. 관리자 화면 인터랙션 가능한 기능들 마우스 커서 변경 미적용
  4. 어드민 system 조회 API 탭별로 4회 중복 호출 → 캐싱 또는 상위에서 단일 호출로 개선 필요
- 차트 라이브러리 방향 (회의 논의): ECharts 우선 검토, chart.js / Recharts도 비교 대상. devextreme 대체 가능성 염두.
- 북마크 → 대시보드 아이디어 (회의 논의): 북마크된 차트·표 카드를 레이아웃에 배치해 커스텀 대시보드 생성. 활용도 제고 목적.
