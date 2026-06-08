---
type: decision-record
project: dna-sql-agent-web
date: 2026-05-28
status: accepted
superseded-by: ""
tags: [error-handling, auth, fetch]
---

# ADR-009: SessionExpiredError 타입 도입

## 맥락

`fetchWithAuth`에서 refresh token 갱신이 실패하면 `new Error('Session expired')`를 throw하고, `auth-session-expired` 이벤트를 dispatch해 UI 리다이렉트를 처리했다.

그런데 이 에러가 call stack을 타고 올라가 `chat-api.ts`의 `if (!res.ok) throw new Error('Get conversation failed: 401')` 등을 거치면서, 최종적으로 `use-conversations.ts`의 catch 블록들이 `console.error`로 출력했다. 세션 만료는 예외 상황이 아닌 정상 흐름임에도 콘솔에 빨간 에러가 다수 찍히는 문제.

기존에는 `err.message !== 'Session expired'` 문자열 비교로 막으려 했으나, chat-api에서 wrapping되면서 메시지가 바뀌어 동작하지 않았다.

## 선택지

### 옵션 A: 401 Response 반환 (throw 대신)
- `fetchWithAuth`가 throw 대신 `new Response(null, { status: 401 })` 반환
- **단점:** `chat-api.ts`의 `if (!res.ok) throw` 패턴이 다시 에러를 만들어 동일 문제 반복. 수십 개 함수 전부 수정 필요

### 옵션 B: SessionExpiredError typed class
- `SessionExpiredError extends Error` export
- catch 블록에서 `instanceof SessionExpiredError`로 구분
- **장점:** 명확한 타입 구분, 콜러가 선택적 처리 가능, chat-api 수정 불필요
- **단점:** 콜러(use-conversations.ts) 모든 catch 블록 수정 필요

### 옵션 C: 문자열 비교 (현상 유지 개선)
- `err.message.includes('401')` 조건 추가
- **단점:** 취약한 문자열 매칭, 향후 메시지 변경 시 재발

## 결정

**옵션 B를 선택한다.**

```ts
export class SessionExpiredError extends Error {
  constructor() {
    super('Session expired')
    this.name = 'SessionExpiredError'
  }
}
```

## 근거

- 세션 만료는 "예상 가능한 실패" → 일반 Error와 타입으로 구분하는 게 의미론적으로 올바름
- `instanceof` 체크는 문자열 비교보다 견고하고 TypeScript 타입 시스템과 잘 맞음
- chat-api.ts 수십 개 함수를 수정하지 않아도 됨

## 결과

- `lib/fetch-client.ts`: `SessionExpiredError` export, refresh 실패 시 throw
- `hooks/use-conversations.ts`: 모든 catch 블록에 `if (err instanceof SessionExpiredError) return` 추가
- 세션 만료 시 콘솔 에러 미출력, UI 전환은 `auth-session-expired` 이벤트가 담당
- 트레이드오프: 새 API 호출 함수를 추가할 때마다 catch 블록에 SessionExpiredError 처리를 기억해야 함

## 참고 자료

- [[sessions/2026-05-28-security-updates-session-expired-error]]
- [[issues/session-expired-console-error]]
- [[knowledge/patterns/typed-error-expected-states]]
