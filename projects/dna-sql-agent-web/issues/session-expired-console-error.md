---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-05-28
resolved: true
root-cause: "fetch-client의 generic Error가 chat-api에서 wrapping되면서 콜러 catch의 문자열 비교 조건을 우회"
related: [decisions/009-session-expired-typed-error]
tags: [auth, error-handling, session]
---

# 세션 만료 시 콘솔 에러 다수 출력

## 증상

```
Failed to load systems: Error: Session expired
Failed to load conversation messages: Error: Get conversation failed: 401
Failed to load conversations: Error: Get conversations failed: 401
```

세션이 만료될 때마다 빨간 에러가 콘솔에 다수 출력됨. 로그인 화면 이동은 정상.

## 환경

- **재현 조건:** localStorage `expiresAt: 0`, `refreshToken: "invalid"` 설정 후 새로고침
- **관련 파일:** `lib/fetch-client.ts`, `lib/chat-api.ts`, `hooks/use-conversations.ts`

## 시도한 것들

1. ❌ `fetchWithAuth`에서 throw 대신 `new Response(null, { status: 401 })` 반환 → chat-api의 `if (!res.ok) throw`가 다시 에러 생성
2. ❌ `err.message !== 'Session expired'` 문자열 비교 — chat-api wrapping 후 메시지가 `'Get conversation failed: 401'`로 바뀌어 조건 미동작
3. ✅ `SessionExpiredError` typed class 도입 + 콜러 `instanceof` 체크

## 근본 원인

`fetchWithAuth` → refresh 실패 → `throw new Error('Session expired')`
→ `chat-api.getConversation` → `if (!res.ok) throw new Error('Get conversation failed: 401')` (wrapping)
→ `use-conversations` catch → 문자열 비교 실패 → `console.error` 출력

즉, fetch-client의 에러가 chat-api 레이어에서 다른 메시지로 wrapping되면서 콜러의 방어 조건을 우회.

## 해결 방법

`SessionExpiredError extends Error` 클래스를 별도로 export.
refresh 실패 시 이 typed error를 throw하면, chat-api에서 wrapping 없이 그대로 전파됨.
콜러(use-conversations)에서 `instanceof SessionExpiredError`로 구분 후 조용히 return.

→ [[decisions/009-session-expired-typed-error]]

## 예방책

"예상 가능한 실패 상태"(세션 만료, 네트워크 오프라인 등)는 generic Error 대신 typed error class를 사용. 문자열 비교는 리팩토링에 취약하므로 사용하지 않는다.

→ [[knowledge/patterns/typed-error-expected-states]]
