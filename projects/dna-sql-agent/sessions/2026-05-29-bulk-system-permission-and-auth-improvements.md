---
type: session-log
project: dna-sql-agent
date: 2026-05-29
duration: 
focus: "시스템 권한 일괄 부여/회수 API 추가 및 인증 개선"
tools-used: [claude-code]
outcome: success
---

# 2026-05-29 — 시스템 권한 일괄 부여/회수 API 추가 및 인증 개선

## 목표

- 시스템 권한을 여러 사용자에게 한 번에 부여/회수하는 API 추가
- 토큰 만료 관련 401 반복 문제 원인 파악 및 수정
- CORS 개인 IP 제거

## 수행한 작업

1. CORS `allow_origins`에서 개인 IP(`172.16.1.42`, `172.16.1.7`) 제거 → `fix/remove-personal-ip-from-cors` 브랜치 커밋
2. 그룹명 최대 32자, 설명 무제한(TEXT) 확인
3. 시스템 권한 일괄 부여 API 설계 — 한 시스템 → 여러 사용자 방향으로 결정
4. `POST /admin/systems/{system_id}/users/bulk` 구현 (granted/skipped 반환)
5. `DELETE /admin/systems/{system_id}/users/bulk` 구현 (revoked 반환)
6. system_id 존재 여부 검증 추가 (404 반환)
7. `user_ids` 빈 배열 방지 (`Field(min_length=1)`)
8. 404 에러 응답에 `code` 필드 추가 (`SYSTEM_NOT_FOUND`) — 향후 다른 404 케이스와 구분 목적
9. `TokenResponse`에 `expires_in` 추가 (초 단위) — 401 반복의 근본 원인 해결
10. `_get_expire_minutes` → `get_expire_minutes` public 함수로 변경
11. `fix/remove-personal-ip-from-cors`를 `feat/admin-improvements`에 병합
12. 브랜치명 `feat/bulk-system-permission` → `feat/admin-improvements`로 변경

## 핵심 결정

- **일괄 API 방향:** 한 사용자에 여러 시스템이 아니라 한 시스템에 여러 사용자로 결정 — 관리자 UI 사용 패턴 기준
  → ADR: [[decisions/005-bulk-system-permission-design]]
- **INSERT...SELECT 패턴:** user_ids 유효성 검증을 별도 SELECT 없이 INSERT INTO...SELECT WHERE 절로 처리
  → ADR: [[decisions/005-bulk-system-permission-design]]
- **에러 응답 code 필드:** HTTP 상태코드만으로 구분 불가한 케이스를 위해 detail에 code 포함

## 배운 것

- FastAPI HTTPException의 `detail`에 dict를 넘기면 그대로 JSON 직렬화됨 → code 필드 패턴 활용 가능
- `INSERT INTO ... SELECT ... WHERE ... ON CONFLICT DO NOTHING RETURNING` 으로 유효성 검증 + 삽입 + 결과 반환을 한 쿼리에 처리 가능

## 문제 & 해결

- **문제:** 토큰 만료로 401이 자꾸 발생
- **원인:** `TokenResponse`에 `expires_in`이 없어 프론트가 토큰 만료 시점을 몰랐음
- **해결:** 로그인/refresh 응답에 `expires_in` (초 단위) 추가

## 다음 할 일

- [ ] `feat/admin-improvements` PR 생성 및 머지
- [ ] 프론트에서 `expires_in` 활용한 refresh 인터셉터 연동 확인
- [ ] 에러 응답 code 패턴 다른 엔드포인트에도 확대 적용 여부 검토
