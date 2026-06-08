---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-05-29
resolved: true
root-cause: "refresh 응답에 expires_in 누락 시 NaN이 JSON null로 직렬화"
related: ["knowledge/troubleshooting/json-nan-serialization"]
tags: [auth, jwt, refresh-token]
---

# JWT refresh 후 모든 요청 401 반복 발생

## 증상

로그인 직후에는 정상 동작하다가, 일정 시간 후 모든 API 요청에서 401이 반복 발생.
`localStorage`의 `jwt_auth.expiresAt` 값이 `null`.

## 환경

- **관련 파일:** `lib/fetch-client.ts`, `components/auth-page.tsx`
- **재현 조건:** 백엔드 refresh 응답에 `expires_in` 필드가 없을 때

## 시도한 것들

1. ✅ `localStorage` 직접 확인 → `expiresAt: null` 발견
2. ✅ `saveTokens` 호출 경로 추적

## 근본 원인

로그인 경로(`use-auth.ts`)는 `expiresIn: number = 1800` 기본값 덕분에 정상 동작.
그러나 refresh 경로(`fetch-client.ts`)는 기본값 없이 `saveTokens(..., newTokens.expires_in)` 호출.
서버가 `expires_in`을 반환하지 않으면 `undefined`가 전달되어:

```
Date.now() + undefined * 1000  →  NaN
JSON.stringify({ expiresAt: NaN })  →  { "expiresAt": null }
```

이후 `authHeaders()`의 `Date.now() >= null` → `Date.now() >= 0` → 항상 `true`
→ 모든 요청에서 Authorization 헤더 제거 → 연속 401

## 해결 방법

```ts
// fetch-client.ts
saveTokens(..., newTokens.expires_in ?? 1800)

// auth-page.tsx
onLogin(data.access_token, email, data.refresh_token ?? '', data.expires_in ?? 1800)
```

## 예방책

- `saveTokens` 호출부 전체에 `?? 1800` fallback 적용
- 근본 해결: 백엔드 refresh 엔드포인트 응답에 `expires_in` 포함 필요

## 관련 페이지

- [[knowledge/troubleshooting/json-nan-serialization]]
