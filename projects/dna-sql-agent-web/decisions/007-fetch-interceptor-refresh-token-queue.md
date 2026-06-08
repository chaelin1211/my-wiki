---
type: decision-record
project: dna-sql-agent-web
date: 2026-05-28
status: accepted
superseded-by: ""
tags: [auth, fetch, interceptor, refresh-token]
---

# ADR-007: 401 인터셉터 + refresh token 큐 패턴

## 맥락

Access token 만료 시간이 24시간 → 30분으로 단축됨. 기존에는 각 API 함수마다 인라인으로 `if (res.status === 401) { handleAuthExpiry() }` 처리했으나, 이 방식으로는 자동 갱신 불가. refresh token을 활용해 사용자가 의식하지 못하게 세션을 갱신해야 함.

## 선택지

### 옵션 A: 함수별 인라인 401 처리 (기존 유지)
- **장점:** 단순, 각 함수에서 명확하게 처리
- **단점:** 갱신 로직 불가, 모든 API 함수에 중복 코드, 만료 시 무조건 로그아웃

### 옵션 B: 중앙화된 `fetchWithAuth()` + 큐 패턴
- **장점:** 갱신 로직 한 곳에서 관리, 중복 refresh 방지, API 함수들 단순화
- **단점:** `refreshTokenApi` / `logoutApi`는 인터셉터 밖에서 호출해야 함 (무한 루프 방지)
- **비용/노력:** 모든 API 파일 교체 (1회성 작업)

### 옵션 C: Axios interceptor
- **장점:** 검증된 패턴
- **단점:** Axios 의존성 추가, 현재 프로젝트가 fetch 기반

## 결정

**옵션 B를 선택한다.** `lib/fetch-client.ts`에 중앙화된 인터셉터를 구현.

## 근거

- 이미 native fetch를 쓰고 있어 Axios 도입은 오버헤드
- 큐 패턴으로 동시 401 중복 refresh 문제 완벽 해결
- API 함수들이 `fetchWithAuth(url, options)` 형태로 단순화되어 가독성 향상

## 핵심 구현 규칙

```typescript
// ✅ plain fetch 사용 (인터셉터 안에서 호출하므로)
async function refreshTokenApi() { return fetch('/api/v1/auth/refresh', ...) }
async function logoutApi() { return fetch('/api/v1/auth/logout', ...) }

// ✅ fetchWithAuth 내부 큐 패턴
let isRefreshing = false
let queue: { resolve; reject }[] = []

// refresh 실패 시 큐 전체 reject (대기 요청들 정상 처리)
queue.forEach(({ reject }) => reject(new Error('Session expired')))
```

## 결과

- 트레이드오프: `refreshTokenApi` / `logoutApi`를 `fetchWithAuth` 안에서 절대 호출하면 안 됨 (룰로 관리)
- `authHeaders()`는 만료 감지 시 `{}` 반환만 해야 함 — localStorage 삭제 금지 (refresh token 보존)
- 향후 재검토: token rotation 방식이 바뀌면 `refreshTokenApi` 응답 파싱 부분만 수정

## 참고 자료

- [[knowledge/patterns/401-interceptor-queue-pattern]]
- 세션 로그: [[sessions/2026-05-28-refresh-token-auto-renewal]]
