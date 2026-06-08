---
type: session-log
project: dna-sql-agent-web
date: 2026-05-28
duration: ~3h
focus: "refresh token 자동 갱신 · 401 인터셉터 · 가상 스크롤"
tools-used: [claude-code]
outcome: success
---

# 2026-05-28 — Refresh Token 자동 갱신 & 가상 스크롤

## 목표

- Access token 만료 시간 24h → 30분 단축에 대응하는 자동 갱신 처리
- 메시지 100개 초과 시 렌더링 안 되는 버그 해결 (가상 스크롤 도입)

## 수행한 작업

1. **`lib/fetch-client.ts` 신규 생성**
   - `fetchWithAuth()`: 401 수신 시 refresh → 재시도 (큐 패턴으로 중복 refresh 방지)
   - `refreshTokenApi()` / `logoutApi()`: plain fetch 사용 (인터셉터 무한 루프 방지)
   - `saveTokens()` / `clearStoredAuth()` / `authHeaders()`: 토큰 저장 유틸리티

2. **`hooks/use-auth.ts` 수정**
   - `AuthData`에 `refreshToken` 필드 추가
   - `login()` 시그니처: `(token, email, refreshToken, expiresIn?)` 로 변경
   - `logout()`: `logoutApi()` 호출 후 토큰 삭제

3. **`components/auth-page.tsx` 수정**
   - 로그인 응답에서 `refresh_token`, `expires_in` 추출해 전달

4. **API 파일 일괄 교체** (auth-api, chat-api, vanna-api, settings-api, sql-api)
   - 로컬 `authHeaders()` / `handleAuthExpiry()` 제거 → `fetchWithAuth()` 적용
   - `checkHealth()` 등 인증 불필요 엔드포인트는 plain fetch 유지

5. **버그 수정 2건**
   - `authHeaders()` 만료 감지 시 localStorage 전체 삭제 → refresh token까지 소멸 → 갱신 불가
   - `use-auth.ts` 마운트 시 access token 만료면 `clearStoredAuth()` 호출 → refresh token 삭제

6. **가상 스크롤 도입** (`@tanstack/react-virtual@3.13.26`)
   - `chat-view.tsx`: `useVirtualizer` 적용, DOM에 뷰포트 범위 메시지만 렌더
   - 스트리밍 중 하단 고정, 위로 스크롤 시 자동 스크롤 중단

7. **PR #21 생성** (`feat/auth` → `main`)

## 핵심 결정

- **401 인터셉터 큐 패턴 채택**: 동시 다발 401 요청 시 refresh를 1회만 보내고 나머지는 대기, 성공 시 일괄 재시도, 실패 시 일괄 reject
  → ADR: [[decisions/007-fetch-interceptor-refresh-token-queue]]

- **refreshTokenApi·logoutApi는 plain fetch 사용**: `fetchWithAuth()` 안에서 호출하면 401 → refresh 무한 루프 발생

- **가상 스크롤 선택**: 페이지네이션 대신 `@tanstack/react-virtual` 도입 — 자연스러운 채팅 UX 유지 + DOM 최적화

## 배운 것

- `authHeaders()` 같은 헬퍼 함수에서 localStorage를 삭제하면 refresh token 같은 부가 데이터까지 사라짐. 만료 감지는 헤더 반환만 하고 삭제는 logout/refresh-fail 경로에서만 할 것
- React hook 바깥의 lib 모듈이 auth 상태를 필요로 할 때는 localStorage 직접 접근이 유일한 방법 (hook 주입 불가)
  → [[knowledge/patterns/401-interceptor-queue-pattern]]

## 문제 & 해결

- **문제:** refresh 성공 후 다음 요청에서 바로 로그인 페이지로 이동
- **원인:** `authHeaders()` 내부에서 만료 감지 시 localStorage 전체 삭제 → refresh token까지 소멸
- **해결:** 만료 시 그냥 `{}` 반환, localStorage는 건드리지 않음
  → 이슈: [[issues/auth-headers-deletes-refresh-token]]

## 다음 할 일

- [ ] 가상 스크롤 커밋 및 PR 포함 여부 확인
- [ ] feat/responsive-ui PR 생성 (반응형 + 권한 매트릭스 UX 개선)
- [ ] 권한 매트릭스 로딩 N+1 개선
