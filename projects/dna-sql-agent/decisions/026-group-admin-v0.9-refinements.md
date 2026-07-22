---
type: decision-record
project: dna-sql-agent
date: 2026-07-22
status: accepted
superseded-by: ""
tags: [auth, permissions, group-admin]
---

# ADR-026: 그룹 관리자 정책 v0.9 — default_grant 자동 시딩, 권한 매트릭스 스코프 제한, 벌크 이동

## 맥락

[[decisions/024-connection-delegation-model|ADR-024]](위임 모델)와
[[decisions/025-default-group-access-initialization|ADR-025]](기본 그룹
예외)로 그룹 관리자 권한 모델의 큰 틀은 확정됐지만, 실사용 직전 점검에서 세
가지 허점이 추가로 드러났다.

1. 커넥션을 그룹에 새로 위임해도 `group_system_default_grants`가 비어있으면
   그 그룹 사용자는 아무 시스템에도 기본 접근 권한이 없다 — 그룹 관리자가
   위임 직후 수동으로 모든 시스템에 대해 기본 권한을 켜줘야 하는 번거로움.
2. 시스템 관리자용 "사용자별 시스템 권한 매트릭스" 화면의 컬럼이 전체
   시스템 목록이라, 그 그룹이 위임받지 않은 시스템에도 실수로 권한을 줄 수
   있었다.
3. 그룹원 관리 다이얼로그에서 여러 명을 한 번에 편입/추방할 때 기존에는
   N번의 개별 `PUT` 호출이었다 — 중간에 하나가 실패하면 일부만 이동된
   상태로 남는다.

## 선택지

허점 1 (default_grant 공백)에 대해:

### 옵션 A: 그룹 관리자가 위임 직후 수동으로 켜도록 안내만 한다
- **장점:** 코드 변경 없음
- **단점:** 신규 위임마다 빠뜨리기 쉽고, 빠뜨리면 그룹원 전체가 시스템에
  접근 못 하는 채로 방치될 위험

### 옵션 B: 위임 시점에 `systems.default_accessible=true`인 시스템을
  자동으로 `default_grant`에 시딩한다
- **장점:** 그룹 관리자가 아무것도 안 해도 "전역 기본 공개" 시스템은 바로
  쓸 수 있음(가입 시 `default_accessible` 자동 부여와 동일한 기대를 유지)
- **단점:** 그룹 관리자가 의도적으로 기본값을 꺼둔 상태가 있다면(예: 위임
  해제 후 재위임) 덮어쓰면 안 됨 — "최초 1회만, 기존 값 있으면 유지" 조건이
  필요해 로직이 한 단계 더 생김

## 결정

**허점 1 → 옵션 B.** 위임 생성 시 `default_accessible` 시스템을 최초 1회만
자동 시딩(기존 레코드가 있으면 건드리지 않음).

**허점 2 →** 권한 매트릭스 화면에서 그룹 선택을 필수화하고, 컬럼을
`GET /admin/groups/{group_id}/available-systems`(그룹 파생 스코프) 응답으로
제한. admin/기본 그룹은 위임 개념이 없으므로([[decisions/025-default-group-access-initialization|ADR-025]])
예외적으로 전체 시스템을 계속 노출.

**허점 3 →** `POST /admin/users/bulk-move`를 신설해 단일 트랜잭션으로
처리(부분 실패 시 전체 롤백). 기존 개별 `PUT` 방식은 폐기.

## 근거

- 세 허점 모두 "그룹 관리자에게 위임했는데 실제로는 아무것도 못 하거나,
  실수로 스코프 밖 권한을 주거나, 대량 작업 중 일부만 반영되는" 형태의
  실사용 마찰이라 v0.9(최초 실사용 배포) 전에 막아야 한다고 판단.
- `default_grant` 자동 시딩은 최초 1회 조건을 둬서, 그룹 관리자가 이후
  수동으로 끈 값을 시스템이 다시 켜버리는 일이 없도록 함 — 자동화와
  그룹 관리자의 수동 제어권을 동시에 보존.

## 결과

- `docs/group-admin-design.md` v0.8 → v0.9 갱신.
- `tests/test_group_admin.py`에 시딩 최초 1회 조건, 매트릭스 스코프 필터,
  벌크 이동 부분 실패 롤백 케이스 추가 — 총 19건.
- 벌크 이동 API 도입으로 프론트 그룹원 관리 다이얼로그의 대량 편입/추방
  UX가 단순해짐(개별 요청 큐잉 로직 제거).

## 참고 자료

- 이전 결정: [[decisions/024-connection-delegation-model]], [[decisions/025-default-group-access-initialization]]
- 정책 문서: `dna-sql-agent/docs/group-admin-design.md` v0.9
- 세션 로그: [[sessions/2026-07-22-group-admin-hardening-and-pr117]]
- PR: 백엔드 #117, 프론트 #72 (둘 다 머지 완료)
