---
type: decision-record
project: dna-sql-agent
date: 2026-07-03
status: accepted
superseded-by: ""
tags: [frontend, layout, sidebar, react]
---

# ADR-020: 라우트에 따라 사이드바 컴포넌트 자체를 교체 (숨김 대신 스왑)

## 맥락

`/dashboard` 진입 시, 기존 화면은 대화 목록 사이드바(`ConversationList`, 접힘 52px)와 대시보드 목록
패널(`DashboardPanel`, 고정 240px)이 **나란히 두 개** 떠 있는 구조였다. 이 상태에서 대시보드
사이드바에도 대화 목록 사이드바와 동일한 상단바(로고·버전·연결 상태·다크모드 토글·접기)와 하단
프로필 메뉴를 붙여야 하는 요구가 생기면서, "사이드바가 두 개"인 구조를 그대로 두고 늘릴지, 하나로
합칠지 결정이 필요했다.

## 선택지

### 옵션 A: 대시보드 사이드바를 대화 목록 사이드바 안쪽에 계속 얹기
- **장점:** 기존 컴포넌트 경계를 안 건드림, 변경 범위 작음
- **단점:** 사이드바가 물리적으로 두 개(52px + 240px) → 화면 낭비, 사용자가 "왜 사이드바가 두 겹이지"로 혼란. 상단바/프로필 메뉴를 두 사이드바 양쪽에 각각 구현해야 해서 중복
- **비용/노력:** 낮음(단기) / 높음(중복 유지보수)

### 옵션 B: 사이드바 자리를 하나로 두고, 라우트에 따라 렌더링되는 컴포넌트를 교체
- **장점:** 사이드바는 항상 하나. `SidebarTopbar`/`SidebarUserMenu`를 공용 컴포넌트로 뽑아 양쪽에서 재사용 가능. 폭(펼침 288px/접힘 52px)과 접힘 상태(`sidebarOpen`)를 전역에서 공유해 채팅↔대시보드 이동 시에도 일관됨
- **단점:** `app/(app)/layout.tsx`가 사이드바 자리에 `ConversationList` vs `DashboardPanel`을 조건부로 렌더링해야 함 — 라우팅 로직과 사이드바 선택 로직이 같은 컴포넌트에 섞임. 대시보드 상태(`DashboardView`가 갖고 있던 목록/상세)를 컴포넌트 바깥(훅 + Context)으로 끌어올려야 함(사이드바와 상세 화면이 서로 다른 렌더 위치에 있으므로)
- **비용/노력:** 중간(구조 변경) / 낮음(장기 유지보수)

## 결정

**옵션 B를 선택한다.** 사이드바는 라우트당 하나이며, `pathname.startsWith('/dashboard')` 여부로
`ConversationList` ↔ `DashboardPanel`을 교체한다.

## 근거

사이드바가 "대화 목록을 보여주는 곳"이 아니라 "현재 화면의 좌측 네비게이션 자리"라는 더 일반적인
역할로 재정의하면, 화면마다 다른 사이드바 콘텐츠가 들어가도 자연스럽다. 상단바/프로필 메뉴 같은
공용 UI를 사이드바 콘텐츠와 분리해 재사용하는 것도 이 구조에서만 깔끔하게 가능하다.

이 결정에는 부수 결정이 따른다 — 대시보드 상태(목록/활성 id/상세)를 소유하던 루트 컴포넌트
(`dashboard-view.tsx`)를 삭제하고, `hooks/use-dashboards.ts` 훅 + `AppContext`(`db`)로 끌어올렸다.
사이드바(`DashboardPanel`)와 상세(`DashboardDetail`)가 이제 `app/(app)/layout.tsx`의 서로 다른 렌더
위치에 있으므로, 상태를 공유하려면 컴포넌트 트리 바깥에 있어야 하기 때문이다. 이는 `conv`/`bm`/`fb`가
이미 따르고 있던 패턴과 동일하다.

## 결과

- 사이드바 펼침/접힘 상태(`sidebarOpen`)가 전역이라, 채팅에서 접어두면 대시보드로 이동해도 접힌
  채로 유지된다(의도된 동작)
- `DashboardPanel`도 `ConversationList`처럼 접힘(52px)/펼침(288px, 메인 사이드바와 동일 폭) 두 상태를
  지원해야 해서 원래 고정폭이던 컴포넌트에 접힘 분기가 추가됨 — 접힘 시 하단 프로필/관리자 링크를
  바닥에 붙이려면 빈 `flex-1` 스페이서가 필요했음(빠뜨리면 접힘 상태에서 하단 요소가 위로 붙어버림,
  실제로 한 번 놓쳤다가 수정)
- 대시보드 목록 로드 로직이 컴포넌트 마운트가 아니라 "섹션 진입"(라우트 기반) 트리거로 바뀌면서,
  로그인 상태 변화도 재로드 조건에 포함시켜야 했다(관련: [[issues/dashboard-account-switch-stale-state]])
- 향후 재검토 시점: 사이드바 콘텐츠가 3종 이상으로 늘어나면(현재 대화 목록/대시보드 2종)
  `layout.tsx`의 조건부 렌더링을 레지스트리 패턴으로 정리할 것

## 참고 자료

- 세션: [[projects/dna-sql-agent/sessions/2026-07-03-sidebar-dashboard-header-refactor]]
- 관련: [[projects/dna-sql-agent-web/decisions/008-app-header-shared-component]] (이번에 삭제된 전역 헤더의 원래 도입 결정)
