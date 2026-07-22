---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-07-16
resolved: true
root-cause: "새 역할(isGroupAdmin) 추가 시 로그인 시점 캐시만 갱신하고, 별도 진입 버튼(sidebar-user-menu)의 노출 조건은 갱신하지 않음"
related: [group-admin-feature]
tags: [auth, rbac, react-state]
---

# 그룹 관리자 지정해도 관리자 페이지에 진입할 방법이 없음

> 신규 "그룹 관리자" 역할 도입 직후 실사용 테스트 중 발견된 두 겹의 버그.

## 증상

1. 시스템 관리자가 사용자 A를 그룹 관리자로 지정한 직후, A 계정으로는:
   - 사이드바에 "그룹 관리" 링크가 뜨지 않음
   - `/admin/group-manage`로 직접 URL 이동해도 즉시 `/`로 리다이렉트됨
2. (1)을 고친 뒤에도, 메인 채팅 화면 좌측 하단의 "관리자" 진입 버튼 자체가
   그룹 관리자 계정에는 표시되지 않아 `/admin`으로 갈 방법이 없었음

## 환경

- **OS:** macOS
- **런타임:** Next.js 15 (App Router), React 클라이언트 컴포넌트
- **관련 패키지:** 자체 `hooks/use-auth.ts` (localStorage 기반 세션 캐시)
- **재현 조건:** 이미 로그인된 세션에서 서버 쪽 역할이 바뀌는 모든 경우 (그룹 관리자
  신규 지정, 회수 등) — 재로그인 전까지 클라이언트가 옛 상태를 그대로 신뢰

## 시도한 것들

1. ✅ `app/admin/layout.tsx`에서 `/admin/*` 진입 시마다 `refreshRole()`을 호출해
   `/api/v1/auth/me`를 다시 조회하고 `isAdmin`/`isGroupAdmin`을 갱신한 뒤 가드 판단
   — 이걸로 (1)은 해결됐지만 (2)는 별개 컴포넌트라 여전히 재현됨
2. ✅ `components/sidebar-user-menu.tsx`의 "관리자" 버튼 노출 조건을
   `isAdmin` → `isAdmin || isGroupAdmin`으로 변경, 이 prop을 넘겨주는 두 호출부
   (`conversation-list.tsx`, `dashboard-panel.tsx`)에도 `isGroupAdmin`을 추가 전달

## 근본 원인

- **(1)의 원인:** `useAuth()`가 `isGroupAdmin`을 로그인 시점에만 `/me`에서 읽어
  localStorage에 캐싱하고, 이후엔 그 캐시만 신뢰. 서버 쪽 역할이 세션 도중 바뀌어도
  클라이언트는 절대 모름.
- **(2)의 원인:** (1)을 고치더라도, "관리자 페이지로 가는 진입점"이 라우트 가드
  하나만이 아니었다. 메인 화면의 버튼은 완전히 다른 컴포넌트(`sidebar-user-menu.tsx`)에
  독립적으로 구현돼 있었고, 그 컴포넌트는 `isGroupAdmin`이라는 개념이 생긴 것 자체를
  몰랐다 — 새 역할을 추가할 때 "이 역할로 갈 수 있는 진입점이 몇 개인가"를 전수
  조사하지 않고 라우트 가드만 고치면 이런 사각지대가 생긴다.

## 해결 방법

```tsx
// app/admin/layout.tsx — 진입 시마다 서버 재검증
useEffect(() => {
  if (isLoading) return
  refreshRole().finally(() => setChecked(true))
}, [isLoading, refreshRole])
// ...checked 이후에만 isAdmin/isGroupAdmin 가드 판단

// components/sidebar-user-menu.tsx — 진입 버튼 조건 확장
{(isAdmin || isGroupAdmin) && isOfficeAddin === false && ( ... )}
```

`refreshRole()`은 `hooks/use-auth.ts`에 신규 추가한 함수로, `/me`를 다시 불러
`saveTokens()`로 캐시를 갱신하고 `window.dispatchEvent(new Event('auth-role-changed'))`를
쏴서 다른 컴포넌트의 `useAuth()` 인스턴스(예: 사이드바)도 같은 프레임에서 함께
갱신되도록 했다 (기존 `auth-session-expired` 이벤트 패턴을 그대로 본떴다).

## 예방책

- 새 역할/권한 플래그를 추가할 때, "이 역할이 필요한 곳"을 라우트 가드 하나로
  끝내지 말고 grep으로 관련 기존 역할(`isAdmin` 등)의 **모든** 사용처를 찾아
  나란히 갱신할지 판단할 것.
- 클라이언트 세션 상태에 role/권한 필드를 추가하면, "이 값이 세션 도중 서버에서
  바뀔 수 있는가?"를 항상 자문할 것 — 바뀔 수 있다면 최소한 권한이 걸린 라우트
  진입 시점에는 재검증 지점을 마련해야 한다.

## 관련 페이지

- [[knowledge/patterns/reverify-role-on-privileged-route-entry|권한 라우트 진입 시 서버 재검증 — 로그인 시점 캐시만 믿지 않기]]
- [[projects/dna-sql-agent-web/sessions/2026-07-16-group-admin-feature|2026-07-16 세션 로그]]
- [[projects/dna-sql-agent/decisions/023-group-admin-role-and-permission-model|ADR-023]]
