---
type: pattern
tags: [react, auth, custom-hook, state-management]
created: 2026-06-16
---

# 인증 상태 단일 진실 공급원 패턴 (React)

## 문제

React 커스텀 훅(`useAuth` 등)을 컴포넌트 트리의 여러 곳에서 독립 호출하면 **각각 별개의 상태 인스턴스**가 생성된다.
한 인스턴스에서 `setToken(null)`을 호출해도 다른 인스턴스는 즉시 알 수 없고, 공유 메커니즘(localStorage 폴링 등)에만 의존하게 된다.

## 증상

- 로그아웃 후 일부 훅/컴포넌트가 이전 사용자 상태를 잔류시킴
- 인증 상태 변화가 즉시 반영되지 않고 수십 초 후에야 해소됨

## 패턴: 최상위 단일 인스턴스 + 하향 주입

```tsx
// ✅ AppProvider — 단 한 곳에서 useAuth() 호출
function AppProvider() {
  const { email, isLoggedIn, login, logout } = useAuth()
  
  // 하위 훅에는 값을 파라미터로 주입
  const conv = useConversations(handleConnect, email ?? null, isLoggedIn)
  
  return <AppContext.Provider value={{ email, isLoggedIn, login, logout, conv }}>
    {children}
  </AppContext.Provider>
}

// ✅ 하위 훅 — useAuth() 직접 호출 금지, 파라미터로 받음
function useConversations(
  onConnect: (ok: boolean) => void,
  email: string | null,
  isLoggedIn: boolean,
) { ... }

// ❌ 안티패턴 — 훅 내부에서 useAuth() 재호출
function useConversations(onConnect) {
  const { email, isLoggedIn } = useAuth()  // 독립 인스턴스!
  ...
}
```

## 적용 기준

- 인증 상태(`token`, `email`, `isLoggedIn`)를 여러 훅이 공통으로 사용할 때
- 로그아웃/로그인 이벤트가 즉시 전파되어야 할 때
- 동일 훅을 컴포넌트 트리의 다른 레벨에서 호출하는 경우

## 관련 이슈

- [[projects/dna-sql-agent/issues/logout-stale-conversation-list]]
