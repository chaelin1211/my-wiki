---
type: decision
project: dna-sql-agent
date: 2026-05-29
status: accepted
---

# ADR-005 시스템 권한 일괄 부여/회수 API 설계

## 맥락

관리자가 특정 시스템에 대해 여러 사용자에게 권한을 한 번에 부여하거나 회수해야 하는 요구사항 발생.

## 결정

### 1. API 방향: 한 시스템 → 여러 사용자

`POST /admin/systems/{system_id}/users/bulk` 방식으로 분리.  
(기존 `POST /admin/users/{user_id}/systems`는 한 사용자에게 시스템 하나씩 부여하는 방식 — 유지)

**이유:** 관리자 UI에서 시스템 기준으로 사용자를 선택하는 패턴이 자연스러움.

### 2. 유효성 검증: INSERT...SELECT 패턴

별도 SELECT로 user_ids를 검증하지 않고, INSERT INTO ... SELECT ... WHERE u.id = ANY($2::uuid[]) 로 한 쿼리에 처리.

```sql
INSERT INTO user_system_permissions (user_id, system_id)
SELECT u.id, $1
FROM users u
WHERE u.id = ANY($2::uuid[])
ON CONFLICT (user_id, system_id) DO NOTHING
RETURNING user_id
```

**이유:** 쿼리 수 최소화, users 테이블에 없는 ID는 자동으로 스킵됨.

### 3. 응답 구조

- 부여: `{ granted: [uuid...], skipped: [uuid...] }` — 이미 권한 있거나 존재하지 않는 유저는 skipped
- 회수: `{ revoked: [uuid...] }` — 실제 삭제된 것만 반환

### 4. 에러 응답 code 필드

system_id 미존재 시 404와 함께 `detail: { code: "SYSTEM_NOT_FOUND", message: "..." }` 반환.  
향후 다른 404 케이스(`USER_NOT_FOUND` 등)와 프론트에서 명확히 구분 가능.

## 결과

- `src/dna/auth/models.py` — `SystemPermissionBulkGrantRequest`, `SystemPermissionBulkGrantResponse`, `SystemPermissionBulkRevokeResponse` 추가
- `src/dna/database/crud.py` — `bulk_grant_system_permission`, `bulk_revoke_system_permission` 추가
- `src/dna/auth/routes.py` — POST/DELETE `/admin/systems/{system_id}/users/bulk` 엔드포인트 추가
