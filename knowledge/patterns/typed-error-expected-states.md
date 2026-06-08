---
type: knowledge
tags: [error-handling, typescript, pattern]
created: 2026-05-28
---

# Typed Error for Expected Failure States

## 문제

네트워크 레이어에서 "예상 가능한 실패"(세션 만료, 오프라인 등)를 generic `Error`로 throw하면:
- 상위 레이어에서 wrapping하면서 메시지가 바뀜
- 콜러의 문자열 비교(`err.message === 'Session expired'`)가 취약해짐
- 콘솔에 불필요한 에러가 출력됨

## 패턴

예상 가능한 실패 상태마다 typed error class를 만든다.

```ts
export class SessionExpiredError extends Error {
  constructor() {
    super('Session expired')
    this.name = 'SessionExpiredError'
  }
}

export class NetworkOfflineError extends Error {
  constructor() {
    super('Network offline')
    this.name = 'NetworkOfflineError'
  }
}
```

콜러에서 `instanceof`로 구분:

```ts
try {
  await someApiCall()
} catch (err) {
  if (err instanceof SessionExpiredError) return  // 조용히 무시, 이벤트로 처리됨
  if (err instanceof NetworkOfflineError) showOfflineBanner()
  else console.error('Unexpected error:', err)
}
```

## 장점

- TypeScript 타입 시스템과 잘 맞음 (`instanceof` 타입 가드)
- 메시지 변경에 취약하지 않음
- 새 레이어에서 wrapping해도 타입이 유지됨 (단, re-throw 시)
- 콜러가 선택적으로 처리 가능

## 주의사항

- 에러를 re-wrap(`new Error(err.message)`)하면 타입이 손실됨 → 항상 `throw err`로 재던질 것
- 새 API 함수 추가 시 catch 블록에 typed error 처리를 기억해야 함

## 실제 적용 사례

- [[projects/dna-sql-agent-web/decisions/009-session-expired-typed-error]]
- [[projects/dna-sql-agent-web/issues/session-expired-console-error]]
