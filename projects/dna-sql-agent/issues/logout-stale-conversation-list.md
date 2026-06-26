---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-16
resolved: true
root-cause: "useConversations 내 독립 useAuth() 인스턴스로 인한 로그아웃 상태 전파 지연 (최대 60초)"
related: []
tags: [react, auth, stale-state, custom-hook]
---

# 로그아웃 후 재로그인 시 이전 계정 대화 목록 표시

## 증상

로그아웃 후 다른 계정으로 재로그인하면 이전 계정의 대화 목록이 그대로 표시됨.
최대 60초 후 자동으로 해소됨.

## 환경

- **프레임워크:** Next.js (App Router)
- **관련 파일:** `hooks/use-conversations.ts`, `hooks/use-auth.ts`, `lib/app-context.tsx`
- **재현 조건:** 계정 A 로그인 → 로그아웃 → 계정 B 로그인

## 시도한 것들

1. ❌ 백엔드 logout 엔드포인트 확인 — 서버 측 문제 아님 (순수 JWT, 쿼리도 user_id 기반 정상 필터링)
2. ✅ 프론트엔드 훅 구조 분석 — `useConversations` 내 독립 `useAuth()` 호출 발견

## 근본 원인

`AppProvider`에서 `useAuth()`를 호출하고, `useConversations` 훅 내부에서도 `useAuth()`를 독립적으로 호출.
React 커스텀 훅은 호출마다 독립 상태 인스턴스를 생성하므로, `AppProvider`의 `logout()` 호출이 `useConversations` 내부 `email`/`isLoggedIn` 상태를 즉시 갱신하지 않음.

`useAuth` 내부 동기화 메커니즘:
- 마운트 시 `getStoredAuth()`로 초기화
- 60초 `setInterval`로 localStorage 재확인
- `auth-session-expired` 이벤트

→ 로그아웃 후 `useConversations` 인스턴스는 최대 60초간 이전 계정 상태를 유지.
→ `reset effect`와 `init effect`가 트리거되지 않아 대화 목록이 갱신되지 않음.

## 해결 방법

```ts
// hooks/use-conversations.ts — Before
const {email, isLoggedIn} = useAuth()  // 독립 인스턴스

// After — 파라미터로 주입받도록 변경
export function useConversations(
  onConnect: (ok: boolean) => void,
  email: string | null,
  isLoggedIn: boolean,
) {
```

```ts
// lib/app-context.tsx
const { email, isLoggedIn, ... } = useAuth()  // 단일 진실 공급원
const conv = useConversations(handleConnect, email ?? null, isLoggedIn)
```

## 예방책

- 인증 상태(`email`, `isLoggedIn`, `token`)는 앱 최상위 컨텍스트에서 단일 `useAuth()` 인스턴스로만 관리
- 하위 훅/컴포넌트는 `useAuth()`를 직접 호출하지 않고 Context나 props를 통해 주입받을 것
- 같은 커스텀 훅을 컴포넌트 트리의 여러 위치에서 호출할 때는 상태 공유 여부 의도를 명확히 할 것

## 관련 페이지

- [[knowledge/patterns/single-auth-source-of-truth]]
