---
type: session-log
project: dna-sql-agent-web
date: 2026-07-16
duration: 
focus: "그룹 관리자(Group Admin) 기능 — 프론트엔드 구현"
tools-used: [claude-code]
outcome: success
---

# 2026-07-16 — 그룹 관리자(Group Admin) 기능: 프론트엔드 구현

## 목표

백엔드에 새로 생긴 "그룹 관리자" 역할(시스템 관리자가 그룹별로 위임하는 관리자,
`is_group_admin` + `group_id`)을 프론트엔드에 반영 — 신규 `/admin/group-manage`
4탭 페이지, 시스템관리자 쪽 그룹↔시스템 매핑/그룹관리자 지정 UI, 역할 인지형
라우팅/사이드바. 정책·백엔드 설계는
[[projects/dna-sql-agent/sessions/2026-07-16-group-admin-feature|dna-sql-agent 세션 로그]] 참고.

## 수행한 작업

1. Auth 상태 확장 — `hooks/use-auth.ts`, `lib/fetch-client.ts`, `lib/chat-api.ts`에
   `isGroupAdmin`/`groupAdminGroupId` 추가. 역할 즉시성 보완용 `refreshRole()` +
   `auth-role-changed` 커스텀 이벤트(기존 `auth-session-expired` 패턴을 본떠 작성)
2. 라우팅/사이드바 — `admin/layout.tsx` 게이트를 `isAdmin || isGroupAdmin`으로 완화,
   `admin/page.tsx` 역할별 리다이렉트(`/admin/agent-config` vs `/admin/group-manage`),
   사이드바에 "그룹 관리" 항목 조건부 노출
3. API 클라이언트 — `lib/auth-api.ts`에 시스템관리자용 매핑/지정 함수, 신규
   `lib/group-admin-api.ts`(그룹관리자 셀프서비스, 백엔드 28개 엔드포인트와 1:1 대응)
4. 시스템관리자용 UI — `group-list.tsx`에 "시스템 매핑"/"그룹 관리자 지정" 다이얼로그
   2개 신규 (admin 그룹 행에는 버튼 숨김)
5. `/admin/group-manage` 4탭 페이지 신규 — 데이터베이스 관리(커넥션은 단독소유만
   편집 가능, 시스템 CRUD/지식화 트리거), 사용자 권한(그룹원×매핑시스템), 기본 권한
   설정(신규편입자 자동부여 토글), 그룹원 관리(기본그룹 경유 편입/추방)
6. 재사용 판단: `ConnectionDialog`는 `onCreate`/`onUpdate` 콜백 기반이라 그룹 스코프
   API만 주입해서 그대로 재사용. `SystemDialog`는 `createSystem`/`updateSystem`
   API 호출이 컴포넌트 내부에 하드코딩돼 있어(콜백 아님) 재사용 불가 판단 →
   `GroupSystemDialog` 신규 작성
7. `tsc --noEmit` 검증 — 신규/수정 파일 0건 오류 (기존 무관 파일 26건 pre-existing
   오류는 이번 변경과 무관)
8. 사용자 실사용 테스트 중 버그 2건 발견·수정 (아래 "문제 & 해결" 참고)

## 핵심 결정

- **결정 1:** 그룹 스코프 DB 관리 컴포넌트는 기존 시스템관리자용 컴포넌트를 억지로
  일반화하지 않고, 콜백 기반인 것만 재사용(`ConnectionDialog`)하고 하드코딩된 것은
  가볍게 새로 작성(`GroupSystemDialog`) — 재사용 압박으로 기존 안정 컴포넌트를
  리팩터링하는 리스크보다 작은 중복을 선택

## 배운 것

- 클라이언트 role/권한 정보를 로그인 시점에만 캐싱(localStorage)하면, 세션 중간에
  권한이 바뀌는 시나리오(그룹 관리자 신규 지정 등)를 놓친다. 권한 있는 라우트에
  진입할 때마다("/admin/*" 레이아웃 레벨) 서버 최신 상태로 재검증하는 게 안전
  → 지식화: [[knowledge/patterns/reverify-role-on-privileged-route-entry|권한 라우트 진입 시 서버 재검증 — 로그인 시점 캐시만 믿지 않기]]
- 새 역할/권한을 추가할 때는 "메인 라우트 가드"뿐 아니라 그 역할로 가는 **모든
  진입점**(사이드바 버튼, 메뉴 항목, 딥링크)을 감사해야 한다 — 이번에 라우트
  가드(`admin/layout.tsx`)는 처음부터 맞게 짰지만, 메인 화면의 "관리자" 버튼
  (`sidebar-user-menu.tsx`)이 `isAdmin`만 보고 있어서 그룹 관리자는 애초에
  들어갈 방법이 없었다.

## 문제 & 해결

- **문제 1:** 그룹 관리자로 막 지정한 계정으로 로그인해도 "그룹 관리" 링크가 안 보이고,
  URL로 직접 들어가도 즉시 `/`로 튕겨나감
  **원인:** `useAuth()`가 로그인 시점에 캐싱한 `isGroupAdmin`만 보고 판단, 재검증 없음
  **해결:** `admin/layout.tsx` 진입 시마다 `refreshRole()`로 `/auth/me`를 다시 불러
  최신 상태로 갱신 후 가드 판단하도록 변경

- **문제 2:** 그룹 관리자 계정으로도 메인 채팅 화면에 "관리자" 진입 버튼 자체가 안 보임
  **원인:** `sidebar-user-menu.tsx`의 버튼 노출 조건이 `isAdmin`만 체크
  **해결:** `isAdmin || isGroupAdmin`으로 변경, 호출부(`conversation-list.tsx`,
  `dashboard-panel.tsx`) 2곳에 `isGroupAdmin` prop 추가 전달
  → 이슈: [[projects/dna-sql-agent-web/issues/group-admin-entry-point-missing|group-admin-entry-point-missing]]

## 다음 할 일

- [ ] 프론트엔드 커밋 (기능 단위로 분리, 사용자 검토 후)
- [ ] 백엔드/프론트 두 워크트리 PR 생성 및 리뷰
- [ ] 실사용 테스트 계속 — 시스템관리자/그룹관리자 두 세션으로 전체 플로우 재확인

## 효과적이었던 프롬프트

```
아니 그냥 그룹 관리자인 사람한텐 관리자 페이지 버튼이 안 뜨는 거 같은데
```
