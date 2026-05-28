---
type: project-status
project: dna-sql-agent-web
updated: 2026-05-28
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
- [x] AppHeader 공통 컴포넌트 추출 — PPT 모드 마이페이지 버튼 숨김 공통 처리 — ADR-008 (fix/bookmark-header-office-addin 브랜치)

## 진행 중

_(없음)_

## 다음 할 일

- [ ] fix/bookmark-header-office-addin PR 생성
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
