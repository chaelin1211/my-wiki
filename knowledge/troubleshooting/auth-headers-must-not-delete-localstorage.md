---
type: troubleshooting
tags: [auth, localstorage, refresh-token, jwt]
related-projects: [dna-sql-agent-web]
date: 2026-05-28
---

# 인증 헬퍼 함수에서 localStorage 삭제하면 refresh token까지 소멸

## 증상

- refresh token이 분명히 저장돼 있는데 "No refresh token" 오류 발생
- access token 만료 직후 refresh 없이 바로 로그아웃

## 원인

`authHeaders()` 같은 읽기 전용 목적의 헬퍼 함수 안에서 만료 감지 시 localStorage를 삭제:

```typescript
// ❌ 안티패턴
function authHeaders() {
  if (Date.now() >= data.expiresAt) {
    localStorage.removeItem('jwt_auth')  // refresh token까지 같이 삭제!
    return {}
  }
}
```

access token과 refresh token을 같은 키(`jwt_auth`)에 JSON으로 저장하면, 해당 키 삭제 시 refresh token도 함께 사라진다.

## 해결

```typescript
// ✅ 만료 시 헤더만 비워 반환 — localStorage 건드리지 않음
function authHeaders() {
  if (Date.now() >= data.expiresAt) return {}
  return { Authorization: `Bearer ${data.token}` }
}
```

localStorage 삭제는 아래 경로에서만 수행:
- `logout()` 명시적 호출
- refresh 실패 (`catch` 블록)

## 교훈

**헬퍼 함수는 읽기 전용으로 설계.** 만료 감지 ≠ 삭제. "만료됐으니 정리하겠다"는 의도가 들어가면 side effect 범위를 명확히 한정할 것.

## 관련

- [[projects/dna-sql-agent-web/issues/auth-headers-deletes-refresh-token]]
- [[knowledge/patterns/401-interceptor-queue-pattern]]