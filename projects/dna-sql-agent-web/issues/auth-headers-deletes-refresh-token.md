---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-05-28
resolved: true
root-cause: "authHeaders()에서 만료 감지 시 localStorage 전체 삭제"
related: [decisions/007-fetch-interceptor-refresh-token-queue]
tags: [auth, refresh-token, localstorage]
---

# refresh 성공 후 다음 요청에서 바로 로그인 페이지로 이동

## 증상

- 첫 번째 401 → refresh → 재시도 요청 성공
- 그 직후 다음 API 요청에서 다시 로그인 페이지로 이동
- 새로고침 후에도 로그인 페이지

## 환경

- **관련 파일:** `lib/fetch-client.ts`, `hooks/use-auth.ts`
- **재현 조건:** access token 만료(30분 경과) 후 임의 API 요청

## 시도한 것들

1. ❌ refresh_token이 새로 저장되지 않는다고 판단 → `saveTokens()`에 refresh_token 포함 확인했으나 이미 저장 중
2. ✅ `authHeaders()` 내부 로직 재확인 → 만료 시 `localStorage.removeItem()` 호출 발견

## 근본 원인

`authHeaders()`가 access token 만료를 감지했을 때 localStorage 전체를 삭제:

```typescript
// ❌ 버그 코드
if (Date.now() >= data.expiresAt) {
  localStorage.removeItem(STORAGE_KEY)  // refresh token까지 삭제됨!
  return {}
}
```

`fetchWithAuth()` 흐름:
1. `buildHeaders()` → `authHeaders()` 호출 → 만료 감지 → **localStorage 삭제**
2. Authorization 헤더 없이 요청 → 401
3. `refreshTokenApi()` → `getStoredAuth()` → **null** (이미 삭제됨)
4. "No refresh token" 예외 → logout

같은 문제가 `use-auth.ts` 마운트 시에도 존재:
```typescript
// ❌ 버그 코드
if (isExpired) {
  clearStoredAuth()  // 페이지 재로드 시 refresh token 삭제
  return
}
```

## 해결 방법

```typescript
// ✅ 수정: 만료 시 헤더만 비워 반환, localStorage 건드리지 않음
if (Date.now() >= data.expiresAt) return {}

// ✅ use-auth.ts 마운트: access token 만료여도 localStorage 유지
// — 첫 API 호출 시 fetchWithAuth 인터셉터가 자동 갱신
setToken(auth?.token ?? null)
setEmail(auth?.email ?? null)
```

localStorage 삭제는 logout / refresh 실패 경로에서만 수행.

## 예방책

- 인증 헬퍼 함수는 **읽기 전용**으로 설계. 삭제/수정은 명시적 logout/refresh 경로에서만.
- refresh token과 access token을 같은 localStorage 키에 저장할 때, 만료 감지 ≠ 전체 삭제.

## 관련 페이지

- [[knowledge/troubleshooting/auth-headers-must-not-delete-localstorage]]
- [[decisions/007-fetch-interceptor-refresh-token-queue]]
