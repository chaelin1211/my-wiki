---
type: pattern
tags: [fetch, auth, interceptor, refresh-token, queue]
related-projects: [dna-sql-agent-web]
date: 2026-05-28
---

# 401 인터셉터 큐 패턴 — 중복 refresh 없이 자동 토큰 갱신

## 문제

SPA에서 access token이 만료될 때 여러 API 요청이 동시에 401을 받으면, 각각이 refresh를 시도해 토큰 rotation 충돌이 발생한다.

## 패턴

```typescript
let isRefreshing = false
let queue: Array<{ resolve: (token: string) => void; reject: (err: Error) => void }> = []

async function fetchWithAuth(url: string, options?: RequestInit): Promise<Response> {
  const res = await fetch(url, { ...options, headers: buildHeaders(options?.headers) })
  if (res.status !== 401) return res

  // 이미 refresh 중이면 큐에서 대기
  if (isRefreshing) {
    return new Promise<string>((resolve, reject) => {
      queue.push({ resolve, reject })
    }).then((newToken) => retryWithToken(newToken, url, options))
  }

  isRefreshing = true
  try {
    const newTokens = await refreshTokenApi()   // plain fetch (인터셉터 밖)
    saveTokens(newTokens)
    queue.forEach(({ resolve }) => resolve(newTokens.access_token))
    return retryWithToken(newTokens.access_token, url, options)
  } catch {
    const err = new Error('Session expired')
    queue.forEach(({ reject }) => reject(err))  // 대기 요청 전부 reject
    clearStoredAuth()
    window.dispatchEvent(new Event('auth-session-expired'))
    throw err
  } finally {
    queue = []
    isRefreshing = false
  }
}
```

## 핵심 규칙

| 규칙 | 이유 |
|------|------|
| `refreshTokenApi()` / `logoutApi()`는 plain fetch | `fetchWithAuth` 안에서 호출하면 401 → refresh 무한 루프 |
| `authHeaders()`는 만료 시 `{}` 반환만, localStorage 삭제 금지 | refresh token까지 소멸됨 |
| refresh 실패 시 큐 전체 reject | 대기 요청들이 무한 대기하지 않도록 |

## 적용 대상

- React/Next.js + native fetch 프로젝트
- JWT access token + refresh token rotation 구조
- 여러 API 모듈이 분산된 경우 (중앙화 효과 큼)

## Axios와 차이

Axios는 `axios.interceptors.response.use()`로 동일 패턴 구현 가능. native fetch는 직접 구현 필요.

## 참고

- dna-sql-agent-web: [[projects/dna-sql-agent-web/decisions/007-fetch-interceptor-refresh-token-queue]]