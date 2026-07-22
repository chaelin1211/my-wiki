---
type: troubleshooting
project: dna-sql-agent
date: 2026-07-03
resolved: true
root-cause: "useDashboards/useBookmarks가 계정(email) 변경 시 초기화되지 않음 + 대시보드 목록 로드가 'hasLoadedRef 최초 1회' 가드와 pathname 의존이라 상태를 리셋해도 재로드 트리거가 안 걸림"
related: [logout-stale-conversation-list]
tags: [react, auth, stale-state, custom-hook, useEffect]
---

# 로그아웃 후 재로그인 시 대시보드/북마크 상태 잔존 → 재로드 안 됨(2단계 버그)

## 증상

1차: 로그아웃 후 다른 계정으로 로그인하면 이전 계정의 대시보드/북마크가 그대로 남아있음.
1차를 고치고 나니 2차 증상 발생: 대시보드를 보다가 로그아웃 → 그냥 다시 로그인하면(같은 계정이어도)
대시보드 화면에 아무것도 안 뜸(빈 화면).

## 환경

- **프레임워크:** Next.js (App Router)
- **관련 파일:** `hooks/use-dashboards.ts`, `hooks/use-bookmarks.ts`, `lib/app-context.tsx`, `app/(app)/layout.tsx`
- **재현 조건 (1차):** 계정 A로 대시보드 진입 → 로그아웃 → 계정 B 로그인 → 대시보드 진입
- **재현 조건 (2차):** 대시보드 화면에서 로그아웃 → 로그인(계정 무관, URL이 `/dashboard/[id]`에 그대로 머문 상태)

## 시도한 것들

1. ✅ (1차) `useDashboards`/`useBookmarks`에 `email` 파라미터 추가, `[email ?? 'not-logged-in']` 의존
   `useEffect`로 상태(목록/활성id/상세/로딩플래그) 전체 리셋 — [[issues/logout-stale-conversation-list]]에서
   `useConversations`에 적용했던 것과 동일 패턴
2. ❌ (2차 발견) 1차 수정만으로는 재로그인 시 빈 화면. 대시보드 목록을 불러오는
   `db.ensureLoaded()`가 `hasLoadedRef`로 "최초 1회만" 실행되도록 가드돼 있고, 이를 호출하는
   `useEffect`가 `pathname` 변화에만 반응하는 구조 — 로그아웃/로그인 중에는 URL(`/dashboard/...`)이
   바뀌지 않으므로 이 effect 자체가 재실행되지 않음. 상태는 비워졌는데 아무도 다시 채워주지 않음
3. ✅ `useEffect` 의존성에 `isLoggedIn` 추가해서 임시 수정
4. ✅ 사용자 지적("그렇게밖에 안 돼? 그냥 진입할 때마다 로드 아냐?")을 받아들여, `hasLoadedRef` 가드
   자체를 제거. `ensureLoaded()` → `loadDashboards()`로 단순화하고, `pathname`이 아니라
   "대시보드 섹션에 있는가"(`isDashboardRoute` boolean)를 의존성으로 둬서 섹션 진입 시마다(로그인
   상태 변화 포함) 다시 불러오도록 정리. `/dashboard/[id]` 간 이동처럼 섹션 안에서만 바뀌는 경우엔
   `isDashboardRoute` 값이 그대로라 불필요한 재호출은 없음

## 근본 원인

두 가지가 겹친 문제였다.

**(1) 리셋 누락:** `useConversations`는 이미 `email` 의존 리셋 effect가 있었지만, 이후 추가된
`useDashboards`/`useBookmarks`는 같은 패턴을 적용받지 못했다. 새 상태 훅을 추가할 때 "계정 전환
시 리셋"이 체크리스트에 없으면 놓치기 쉽다.

**(2) "최초 1회 로드" 가드가 재트리거를 막음:** `hasLoadedRef.current`로 한 번 로드하면 다시는
안 부르도록 막아둔 설계는, "컴포넌트가 리마운트되면 자연히 다시 로드된다"는 암묵적 전제 위에
있었다. 그런데 이 세션에서 사이드바 구조를 바꾸며 `DashboardPanel`이 더 이상 리마운트되지 않게
됐고(라우트가 안 바뀌면 컴포넌트도 안 바뀜), 상태만 리셋되고 가드는 그대로 남아 "리셋됐지만
아무도 다시 안 채움"이라는 사각지대가 생겼다.

## 해결 방법

```ts
// hooks/use-dashboards.ts — 계정 전환 시 리셋
export function useDashboards(email: string | null) {
  const [dashboards, setDashboards] = useState<Dashboard[]>([])
  // ...
  useEffect(() => {
    activeIdRef.current = null
    setDashboards([])
    setIsListLoading(false)
    setActiveIdState(null)
    setDetail(null)
    setIsDetailLoading(false)
  }, [email ?? 'not-logged-in'])
  // ...
}
```

```tsx
// app/(app)/layout.tsx — "최초 1회" 가드 제거, 섹션 진입 시마다 로드
const isDashboardRoute = pathname.startsWith('/dashboard')
useEffect(() => {
  if (isLoggedIn && isDashboardRoute) void db.loadDashboards()
}, [isDashboardRoute, isLoggedIn, db.loadDashboards])
```

## 예방책

- 계정(인증 상태)에 종속된 데이터를 들고 있는 커스텀 훅을 새로 만들 때는, `useConversations`처럼
  "계정 전환 시 리셋" `useEffect`를 기본 체크리스트에 포함시킬 것
- "최초 1회만 실행" 가드(`useRef` 플래그)는 "컴포넌트가 절대 리마운트되지 않는다"는 전제가 깨지는
  순간(리마운트 방지 최적화, 라우트 구조 변경 등) 조용히 버그가 된다 — 가드보다는 "언제 다시
  실행돼야 하는가"를 명시적인 의존성으로 표현하는 편이 안전
- 사용자 리포트가 "안 되던 게 됐다가 또 안 된다" 식으로 반복되면, 1차 수정이 근본 원인의 일부만
  건드렸을 가능성을 의심할 것 (이번 건은 정확히 그 패턴)

## 관련 페이지

- [[projects/dna-sql-agent/issues/logout-stale-conversation-list]] (같은 계열의 이전 버그 — 원인은 다름:
  `useConversations` 내 독립 `useAuth()` 인스턴스)
- [[knowledge/patterns/single-auth-source-of-truth]]
- 세션: [[projects/dna-sql-agent/sessions/2026-07-03-sidebar-dashboard-header-refactor]]
- ADR: [[projects/dna-sql-agent/decisions/020-context-sensitive-sidebar-swap]]
