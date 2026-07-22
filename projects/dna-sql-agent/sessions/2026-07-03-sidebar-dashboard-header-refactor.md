---
type: session-log
project: dna-sql-agent
date: 2026-07-03
duration: long
focus: "사이드바/헤더 구조 개편 — 대시보드 사이드바가 대화 목록 자리 대체, 전역 헤더를 사이드바로 흡수, 로그인 전환·전환 애니메이션 버그 다수 수정"
tools-used: [claude-code]
outcome: success
---

# 2026-07-03 — 사이드바/헤더 구조 개편 및 대시보드 안정화

> 프론트엔드(`dna-sql-agent-web`) 브랜치 `refactor/uiux`에서 진행. PR [#66](https://github.com/DnA-Platform-Development-Team/dna-sql-agent-web/pull/66) 머지 완료.
> 곁가지로 백엔드(`dna-sql-agent`) 서비스 매뉴얼 문서를 갱신하고 PR [#96](https://github.com/DnA-Platform-Development-Team/dna-sql-agent/pull/96)으로 이슈 [#67](https://github.com/DnA-Platform-Development-Team/dna-sql-agent/issues/67) 클로즈.

## 목표

- 대시보드 화면에서 대화 목록 사이드바와 대시보드 목록 패널이 나란히 겹쳐 보이던 이중 사이드바 구조 정리
- 전역 상단 헤더(로고·버전·연결 상태·다크모드 토글)를 없애고 콘텐츠 영역을 넓게 사용
- 그 과정에서 드러난 대시보드 로딩/전환 관련 버그들(계정 전환 시 상태 잔존, 화면 깜빡임, 스크롤 불가) 수습

## 수행한 작업

1. **대시보드 사이드바 승격** — `/dashboard` 진입 시 사이드바 자리에 `ConversationList` 대신 `DashboardPanel`을 렌더링하도록 `app/(app)/layout.tsx` 구조 변경. 대시보드 상태를 컴포넌트가 직접 들고 있던 `dashboard-view.tsx`(루트 컴포넌트)를 삭제하고 `hooks/use-dashboards.ts` 훅 + `AppContext`(`db`)로 이전
2. **공용 사이드바 컴포넌트 신설** — `SidebarTopbar`(로고/버전/연결 상태 점/다크모드 토글/접기 버튼, 접힘 시 로고 하나로 축소되고 hover 시 펼치기 아이콘 전환), `SidebarUserMenu`(관리자 링크 + 프로필, 클릭 시 매뉴얼/설정 팝업). `ConversationList`와 `DashboardPanel` 양쪽에서 공용으로 사용, 접힘(52px)/펼침(288px, 메인 사이드바와 동일 폭) 상태를 동일하게 지원
3. **전역 `MainHeader`/`AppHeader` 삭제** — 로고·버전·연결 상태·다크모드 토글이 사이드바로 이전되며 대체됨. `ChatHeader`는 순수 서브 헤더(제목·시스템 뱃지·보고서 버튼)로만 남음
4. **계정 전환 시 상태 잔존 버그 수정** (사용자 리포트 2건) — `useDashboards`/`useBookmarks`가 `email` 변경 시 초기화되지 않아 로그아웃 후 다른 계정 로그인 시 이전 계정 데이터가 남아있던 문제. 1차 수정(상태 초기화)만으로는 재로그인 후 빈 화면만 남는 2차 버그가 발생 — 대시보드 목록 로드가 `hasLoadedRef` "최초 1회만" 가드 + `pathname` 의존성 조합이라 상태를 리셋해도 재로드 트리거가 안 걸리는 구조였음. `isLoggedIn`을 의존성에 추가하고 결국 가드 자체를 제거, "대시보드 섹션에 들어올 때마다" 로드하는 방식으로 단순화 → [[issues/dashboard-account-switch-stale-state]]
5. **대시보드 전환 시 화면 깜빡임 + 스크롤 불가 수정** (사용자 리포트 다수, 왕복 디버깅) — `DashboardDetail`이 전환마다 통째로 언마운트→스켈레톤→재마운트되며 그래프까지 처음부터 다시 그려지던 문제. `loadDetail`이 즉시 `detail`을 `null`로 비우던 걸 제거해 이전 화면 유지하며 매끄럽게 전환하도록 변경. 이어서 발견된 별개의 원인 — 옛 `dashboard-view.tsx`가 갖고 있던 `h-full`을 잃어버려 `DashboardDetail` 루트 높이가 `auto`로 계산되고 부모의 `overflow-hidden`에 그냥 잘리던(스크롤 불가) 문제. 로딩 dim 연출(`opacity-50`)도 결국 완전히 제거해 전환 시 아무 연출 없이 조용히 교체되도록 정리 → [[issues/dashboard-transition-height-chain-flicker]]
6. **전체 새로고침에 위젯별 스피너 반영** — `handleRefreshAll`이 부모에서 직접 fetch를 돌리고 위젯 컴포넌트의 자체 `isRefreshing` 상태는 건드리지 않아, 개별 위젯에는 로딩 표시가 없던 것을 `forceRefreshing` prop으로 연결. 차트 데이터 반영은 기존처럼 전체 완료 후 일괄 적용(부분 새로고침 후 원복 방지 유지)하되, 스피너는 위젯별 요청이 끝나는 대로 개별적으로 꺼서 진행 상황을 보여줌
7. **오피스 애드인 마이페이지 접근 제한** — `SidebarUserMenu` 팝업에서 매뉴얼은 애드인에서도 노출하되 설정(마이페이지)만 `isOfficeAddin` 조건으로 숨기도록 분리 (사용자 직접 수정)
8. **설계 문서(`docs/`) 갱신** — `dashboard-design.md`, `chat-design.md`에 위 구조 변경(레이아웃/라우팅/컴포넌트 계층/상태 관리) 반영, 실제 코드와 어긋나 있던 옛 서술(예: `ChatHeader`에 설정·테마 있다는 설명, 존재하지 않는 파일 목록)도 함께 정정
9. **백엔드 서비스 매뉴얼 갱신 + PR 생성** — 프론트 사이드바 개편으로 "설정 진입은 헤더 톱니바퀴" 같은 옛 안내가 틀어져서 `app_manual.md`/`app_manual_admin.md`의 로그아웃·설정·관리자 진입 경로 설명을 사이드바 하단 프로필 기준으로 수정. 백엔드 PR #96으로 이슈 #67("Agent에게 서비스 설명 요청 시 매뉴얼 도구화") 클로즈 — 화면과 LLM 도구(`AppManualTool`)가 같은 마크다운 파일을 단일 출처로 공유하는 구조였음을 재확인
10. PR #66(프론트)·#96(백엔드) 생성 및 머지 확인

## 핵심 결정

- **결정 1:** 대시보드 화면에서 대화 목록 사이드바를 감추는 대신, 사이드바 컴포넌트 자체를 라우트에 따라 `ConversationList` ↔ `DashboardPanel`로 교체 — 두 사이드바가 동시에 보이던 문제를 "하나의 사이드바 자리, 내용물만 다름" 구조로 해소
  → ADR: [[decisions/020-context-sensitive-sidebar-swap]]
- **결정 2:** 대시보드 전환 시 이전 데이터를 유지한 채로 새 데이터가 도착하면 교체("silent swap") — 언마운트 기반 스켈레톤 전환은 리스트/그리드처럼 무거운 하위 트리(react-grid-layout + 차트 다건)에서 눈에 띄는 깜빡임을 유발하므로 지양

## 배운 것

- "최초 1회만 로드" 가드(`hasLoadedRef`)는 인증 상태 변화처럼 컴포넌트가 리마운트되지 않는 시나리오에서 재로드를 막는 함정이 되기 쉽다 — 로그인/로그아웃을 가로지르는 데이터 훅은 "가드"보다 "의존성 배열에 인증 상태 포함"이 더 견고함
- 컴포넌트를 의도적으로 리마운트되지 않게(언마운트 방지) 만들면, `useState(prop)` 형태의 최초값 초기화 로직들(`localTitle`, `localStyle` 등)이 더 이상 자동으로 갱신되지 않는다는 걸 놓치기 쉽다 — prop이 바뀌는 지점(`useEffect([id])`)에서 함께 동기화해줘야 함
- `flex-1`/`h-full` 체인은 중간에 `display:flex`가 아닌 부모가 하나만 끼어도, 그 부모 자체는 높이를 잘 받아도 자식에게 `h-full`을 명시하지 않으면 자식은 `height:auto`로 붕 뜬다 — 부모의 `overflow-hidden`이 이를 "스크롤 안 되고 그냥 잘림"으로 위장해서 원인 추적이 오래 걸림 → [[knowledge/troubleshooting/flex-height-chain-broken-by-missing-h-full]]

## 문제 & 해결

- **문제:** 로그아웃 후 다른 계정으로 로그인해도 이전 계정의 대시보드가 남아있음
- **원인:** `useDashboards`가 계정(email) 변경 시 초기화되지 않음
- **해결:** `email`을 의존성으로 하는 리셋 `useEffect` 추가
  → 이슈: [[issues/dashboard-account-switch-stale-state]]

- **문제:** (위 수정 직후) 대시보드 보다가 로그아웃 → 재로그인하면 아무것도 안 뜸
- **원인:** 목록 로드 effect가 `pathname` 의존이라, URL이 그대로면(로그아웃해도 라우트 이동 없음) 재로드 트리거 자체가 안 걸림
- **해결:** `isLoggedIn`을 의존성에 추가, 최종적으로 "최초 1회" 가드 제거하고 섹션 진입 시마다 로드
  → 이슈: [[issues/dashboard-account-switch-stale-state]]

- **문제:** 대시보드 전환 시 스켈레톤 깜빡임 + 위젯 사이즈 재계산 + 차트 재렌더가 겹쳐서 어지러움
- **원인:** 전환마다 `detail`을 즉시 `null`로 비워 `DashboardDetail`이 언마운트→재마운트됨
- **해결:** `null`로 비우지 않고 새 데이터 도착 시에만 교체(기존 콘텐츠 유지)
  → 이슈: [[issues/dashboard-transition-height-chain-flicker]]

- **문제:** (위 수정 후에도) 대시보드 화면 스크롤이 안 됨
- **원인:** 옛 `DashboardView` 삭제로 `h-full`을 물려주던 조상이 사라져, `DashboardDetail` 루트가 `height:auto`가 되고 부모 `overflow-hidden`에 그냥 잘림(스크롤 아님)
- **해결:** `DashboardDetail`/`DashboardDetailSkeleton` 루트에 `h-full` 명시적으로 추가
  → 이슈: [[issues/dashboard-transition-height-chain-flicker]]

## 다음 할 일

- [ ] (이전 세션 이월) 다중 쿼리 수행 내역이 reload/대화 전환 시 사라짐 — components 영속화 경합(SaveComponentsMiddleware ↔ ChatSaveHook) 조사
- [ ] 브라우저에서 최종 회귀 확인(사용자가 직접 검증 중이었음, 세션 종료 시점 마지막 확인 항목: 대시보드 전환 무깜빡임)

## 효과적이었던 프롬프트

```
지금 대시보드 사이드바 수정 했는데 접었을 때, 사용자 프로필, 관리자 페이지 링크 아이콘이 왜 바닥에 안 붙어있지
```
→ 증상만 짧게 던져도 관련 컴포넌트(`DashboardPanel` 접힘 분기)를 좁혀서 바로 원인(빈 flex-1 스페이서 누락)을 찾을 수 있었음. "왜 ~하지" 형태로 관찰한 사실만 전달하는 프롬프트가 이 세션 전반에서 잘 통했다.
