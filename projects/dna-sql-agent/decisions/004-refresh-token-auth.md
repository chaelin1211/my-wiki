---
type: decision-record
project: dna-sql-agent
date: 2026-05-27
status: accepted
superseded-by: ""
tags: [auth, jwt, refresh-token, access-token]
---

# ADR-004: Refresh Token 도입 및 Access Token 만료 시간 단축

## 맥락

기존 인증은 access token 단일 방식으로, TTL을 24시간으로 설정했다.
이 방식은 토큰 탈취 시 최대 24시간 동안 공격자가 인증된 사용자처럼 API를 호출할 수 있다는 보안 취약점이 있다.
그렇다고 TTL을 짧게 하면 사용자가 자주 재로그인해야 해서 UX가 나빠진다.

## 선택지

### 옵션 A: 기존 유지 (단일 access token, 24시간)
- **장점:** 구현 단순, 프론트엔드 수정 없음
- **단점:** 토큰 탈취 시 노출 시간이 최대 24시간, 강제 만료 불가

### 옵션 B: Access token 만료 단축만 적용 (refresh 없음)
- **장점:** 보안 개선
- **단점:** 사용자가 30분마다 재로그인해야 함 → UX 심각하게 저하

### 옵션 C: Refresh token 도입 + Access token 만료 단축
- **장점:** 짧은 access token(보안) + 자동 갱신(UX) 모두 확보
- **단점:** 프론트엔드에 401 인터셉터·큐 패턴 구현 필요, 토큰 2종 관리

## 결정

**옵션 C를 선택한다.**

| 토큰 | TTL |
|------|-----|
| access token | 30분 |
| refresh token | 7일 |

신규 엔드포인트:
- `POST /api/v1/auth/refresh` — refresh token으로 새 토큰 쌍 발급
- `POST /api/v1/auth/logout` — 로그아웃 (향후 블랙리스트 연동 포인트)

## 근거

- access token TTL 30분: 탈취 시 피해를 30분으로 제한
- refresh token으로 자동 갱신: 사용자 재로그인 없이 7일간 세션 유지
- refresh token도 응답마다 교체(rotation): 탈취된 refresh token의 재사용 기회를 줄임
- 서버 DB에 refresh token을 저장하지 않는 stateless 방식 채택(현재): 구현 복잡도 최소화. 강제 로그아웃 필요 시 블랙리스트 도입으로 확장 가능

## 결과

- 프론트엔드: 401 인터셉터 + 큐 패턴 구현 필요 (`lib/auth-api.ts`)
- 로그인 응답 스키마 변경: `refresh_token` 필드 추가
- 토큰 만료 정책은 env로 관리 (`JWT_EXPIRE_MINUTES`, `JWT_REFRESH_EXPIRE_DAYS`)
- 향후 재검토 시점: 강제 로그아웃(관리자 기능) 요구 발생 시 → 블랙리스트(DB 저장) 방식으로 전환 검토

## 참고 자료

- `src/dna/auth/jwt_utils.py`
- `src/dna/auth/routes.py`
- `docs/refresh-token-frontend-guide.md`
- [[decisions/003-sse-done-event-message-id]]
