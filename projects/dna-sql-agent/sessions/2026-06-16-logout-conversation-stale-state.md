---
type: session-log
project: dna-sql-agent
date: 2026-06-16
duration: ~1h
focus: "로그아웃 후 재로그인 시 이전 계정 대화 목록 표시 버그 수정"
tools-used: [claude-code]
outcome: success
---

# 2026-06-16 — 로그아웃 후 이전 계정 대화 목록 표시 버그 수정

## 목표

로그아웃 후 다른 계정으로 재로그인 시 이전 계정의 대화 목록이 표시되는 버그 수정.

## 수행한 작업

1. 백엔드 logout 엔드포인트 확인 — 순수 JWT 방식(클라이언트 토큰 폐기), 서버 측 무효화 없음
2. `list_conversations` API 확인 — `user_id` 기반 필터링 정상
3. 프론트엔드 `useConversations` / `useAuth` / `AppProvider` 코드 분석
4. 근본 원인 파악: `useConversations` 내부에서 `useAuth()`를 독립 호출하여 `AppProvider`와 별개 상태 인스턴스 생성
5. 수정: `useAuth()` 내부 호출 제거, `email`/`isLoggedIn`을 파라미터로 받도록 변경
6. `AppProvider`에서 단일 `useAuth()` 인스턴스의 값을 `useConversations`에 주입
7. 브랜치 `fix/logout-conversation-stale-state` 생성 및 커밋

## 핵심 결정

- **`useAuth` 인스턴스 통합:** `useConversations`가 자체 `useAuth()`를 호출하지 않고 부모(`AppProvider`)로부터 `email`/`isLoggedIn`을 주입받는 단방향 흐름 유지
  → 이슈: [[issues/logout-stale-conversation-list]]

## 배운 것

- React 커스텀 훅은 호출될 때마다 독립적인 상태 인스턴스를 생성한다. 같은 `useAuth()`를 두 곳에서 호출하면 상태 동기화가 localStorage 폴링(60초 주기)에만 의존하게 됨.
- 인증 상태는 앱 최상위(AppProvider)에서 단일 진실 공급원으로 관리하고, 하위 훅에는 값만 주입해야 한다.

## 문제 & 해결

- **문제:** 로그아웃 후 재로그인 시 이전 계정 대화 목록이 최대 60초간 잔류
- **원인:** `useConversations` 내부 `useAuth()` 독립 인스턴스 — `AppProvider`의 로그아웃/로그인 상태 변경이 즉시 전달되지 않음
- **해결:** `useConversations` 시그니처 변경 (`email: string | null, isLoggedIn: boolean` 파라미터 추가), `AppProvider`에서 직접 주입
  → 이슈: [[issues/logout-stale-conversation-list]]

## 다음 할 일

- [ ] fix/logout-conversation-stale-state PR 생성 및 머지
- [ ] 대시보드 기능 PR 생성 및 머지 (백엔드 feat/dashboard, 프론트엔드)
