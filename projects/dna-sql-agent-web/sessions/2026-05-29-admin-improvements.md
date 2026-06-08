---
type: session-log
project: dna-sql-agent-web
date: 2026-05-29
duration: ~3h
focus: "관리자 페이지 개선 — 권한 일괄 부여/해제, 인증 버그픽스, UI 정렬, SQL 예제 낙관적 업데이트"
tools-used: [claude-code]
outcome: success
---

# 2026-05-29 — 관리자 페이지 개선 (feat/admin-improvements)

## 목표

- 권한 매트릭스에 시스템별 일괄 부여/해제 기능 추가
- 401 반복 발생 원인 파악 및 수정
- DB 관리 테이블 헤더/셀 정렬 및 너비 고정
- SQL 예제 상태 토글 깜빡임 제거

## 수행한 작업

1. **권한 일괄 부여/해제 UI** (`permission-list.tsx`)
   - 시스템 컬럼 헤더에 `CheckSquare`/`Square` 토글 버튼 추가
   - 전원 보유 시 → 일괄 해제, 아니면 → 일괄 부여
   - 확인 AlertDialog: grant/revoke에 따라 문구/버튼 색상 분기
   - 완료 후 `loadAllPermissions()` 대신 `updateMatrixPerm()` 로컬 업데이트 (깜빡임 방지)

2. **Bulk API 연동** (`auth-api.ts`)
   - `bulkGrantPermission`: `POST /admin/systems/{id}/users/bulk`
   - `bulkRevokePermission`: `DELETE /admin/systems/{id}/users/bulk`
   - 빈 배열 early return (422 방지)
   - 404 시 응답 body의 `detail.code`로 메시지 매핑 (`ERROR_CODE_MESSAGES`)

3. **인증 버그픽스** (`fetch-client.ts`, `auth-page.tsx`)
   - refresh 응답에 `expires_in` 누락 시 `NaN` → JSON `null` 저장 → 모든 요청 401 발생
   - `?? 1800` fallback 추가 (두 곳 모두)
   - → [[issues/expires-in-null-bug]]

4. **DB 관리 테이블 스타일** (`connection-list.tsx`, `system-list.tsx`, `sql-examples-table.tsx`)
   - 헤더 전체 `text-center`
   - 뱃지/버튼/토글 셀에 `text-center` 또는 `justify-center`
   - 단일 뱃지 컬럼 `110px`, 토글 컬럼 `130px` 고정

5. **SQL 예제 상태 토글 낙관적 업데이트** (`use-sql-examples.ts`, `sql-examples-table.tsx`)
   - 기존: API 후 `fetchExamples()` 전체 재조회 → 깜빡임
   - 변경: `setPageResponse`로 해당 항목만 로컬 업데이트
   - 테이블 컴포넌트에 `optimisticStatuses` 맵으로 즉각 반영

6. **SQL 예제 컬럼 너비 조정**: 질의 `200→260px`, 태그 `140→100px`

## 핵심 결정

- **Bulk API 사용**: N번 개별 호출 → 1번 bulk 호출로 교체. 서버가 skip 로직 담당
- **에러 코드 매핑**: `ERROR_CODE_MESSAGES` 상수로 code → 한국어 메시지 관리
- **낙관적 업데이트 레벨**: 토글처럼 단순한 변경은 재조회 없이 로컬 상태만 갱신

## 문제 & 해결

- **문제:** 30분 이내에도 401 반복 발생
- **원인:** refresh 응답에 `expires_in` 없을 때 `Date.now() + undefined * 1000 = NaN` → JSON 직렬화 시 `null` → `authHeaders()`에서 항상 빈 헤더 반환
- **해결:** `newTokens.expires_in ?? 1800` fallback 추가
  → [[issues/expires-in-null-bug]]

## 다음 할 일

- [ ] SQL 예제 에디터 긴 한 줄 자동 줄바꿈 (`sql-editor.tsx`) — scrollHeight auto-resize 구조 개선 필요
- [ ] feat/admin-improvements 브랜치 PR 생성
