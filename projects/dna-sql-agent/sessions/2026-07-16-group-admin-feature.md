---
type: session-log
project: dna-sql-agent
date: 2026-07-16
duration: 
focus: "그룹 관리자(Group Admin) 기능 — 정책 설계 + 백엔드 구현"
tools-used: [claude-code]
outcome: success
---

# 2026-07-16 — 그룹 관리자(Group Admin) 기능: 정책 설계 + 백엔드 구현

## 목표

시스템 사용자 증가로 시스템 관리자(admin)가 사용자 1명 단위로 시스템 접근 권한을
관리하는 부담이 커져, 그룹 단위로 위임 관리가 가능한 "그룹 관리자" 역할을 추가.
정책 문서 작성 → 사용자 확인 → 백엔드/프론트엔드 구현까지 한 세션에서 진행
(프론트엔드는 dna-sql-agent-web 세션 로그 참고).

## 수행한 작업

1. `docs/group-admin-design.md` 정책 문서 작성 (v0.1 → v0.3, 반복 확정)
   - 역할 정의: 시스템 관리자(기존 admin 그룹 유지) / 그룹 관리자(그룹 소속 사용자에게
     겸직시키는 역할, 별도 그룹 아님) / 일반 사용자
   - 이중 권한 레이어: 그룹↔시스템 매핑(신규, 상한선/정책 테이블) vs 기존
     `user_system_permissions`(실제 접근 판정 기준) — 그룹 매핑은 그룹 관리자가
     권한을 줄 수 있는 범위를 제한할 뿐, 그 자체로 접근 권한을 주지 않음
   - 확정된 정책: 커넥션은 "단독 소유"(그룹에 배타적으로 매핑된 시스템만 걸린 경우)일
     때만 그룹 관리자가 편집 가능. 그룹 이동(편입/추방)은 기본 그룹 경유만 허용, 이동
     시 이전 권한은 그룹 매핑 여부와 무관하게 전량 회수 후 새 그룹의 default_grant
     시스템만 재부여. 그룹 관리자는 active 사용자만 가능, 비활성화 시 즉시 역할 해제.
     그룹 관리자 0명 허용(시스템 관리자가 기존 화면으로 대행)
   → ADR: [[projects/dna-sql-agent/decisions/023-group-admin-role-and-permission-model|023-group-admin-role-and-permission-model]]

2. 워크트리(`worktree-group-admin`)에서 백엔드 구현
   - 스키마: `groups.is_default`, `group_system_mappings`(그룹↔시스템 매핑 + 그룹별
     default_grant 플래그를 한 테이블에), `group_admins`(그룹 관리자 지정, junction table)
   - `auth/deps.py`: DB 조회 기반 `require_group_admin`/`require_group_admin_for_group`
     신규 (JWT claim 방식은 기각 — 비활성화 시 즉시 반영 요구사항 위반)
   - 신규 `src/dna/group_admin/` 모듈: `crud.py`(매핑/지정/`move_user_group` 트랜잭션),
     `routes.py`(그룹 관리자 셀프서비스 API 28개 엔드포인트)
   - 기존 `database/routes.py` 핸들러 함수를 스코프 체크 뒤에서 직접 호출(위임)하는
     방식으로 시스템/커넥션/벡터라이즈/SQL예제 로직 중복 없이 재사용
     — 해당 함수들이 `user` 파라미터를 FastAPI 의존성 바인딩 용도로만 받고 본문에서
     쓰지 않는다는 걸 확인하고 채택
   - `auth/routes.py`의 `update_user`(그룹 변경 시 기존엔 auto-grant만 하고 revoke 안
     하던 버그) → `move_user_group` 호출로 교체하며 버그 수정 겸함. `register()`의
     하드코딩된 `"user"` 문자열도 `is_default` 조회로 교체
   - 테스트 16건 신규 작성 (`tests/test_group_admin.py`) — 그룹 이동 시 권한 전량회수,
     매핑 삭제 시 자동회수, 비활성화 시 즉시 역할해제, 단독소유 커넥션 판정, 대화이력
     보존 회귀. 기존 45건 회귀 없음 확인

## 핵심 결정

- **결정 1:** 그룹 매핑과 사용자 권한을 이중 레이어로 분리 (매핑=상한선, 사용자권한=실제판정)
  → ADR: [[projects/dna-sql-agent/decisions/023-group-admin-role-and-permission-model|023]]
- **결정 2:** `require_group_admin`을 JWT claim이 아닌 DB 조회 기반으로 구현
  → ADR: [[projects/dna-sql-agent/decisions/023-group-admin-role-and-permission-model|023]]
- **결정 3:** 그룹 관리자 API는 기존 `database/routes.py` 핸들러를 직접 호출(위임)해
  재사용 — 병렬 라우터 + 스코프체크 후 delegation, 별도 CRUD 재구현 안 함

## 배운 것

- FastAPI 라우트 핸들러 함수는 `Depends()` 기본값 파라미터를 명시적으로 오버라이드해
  직접 호출 가능 — 본문에서 그 파라미터를 실제로 쓰지 않는다면(grep으로 확인 가능)
  다른 인가 계층 뒤에서 안전하게 재사용(위임)할 수 있다. 로직 중복 없이 스코프만
  다른 API 표면을 만들 때 유용한 패턴.
- `main.py`를 직접 `import`하면 FastAPI `startup_event`가 실제로 실행되어 실 DB에
  연결하고 백그라운드 잡 러너(CollectionRunner 등)까지 기동됨 — 모듈 임포트만으로
  앱을 켜는 건 위험, 라우터 등록 확인은 서브모듈만 임포트하거나 `ast.parse`로 문법만
  검증할 것.

## 문제 & 해결

- **문제:** 프론트에서 워크트리로 테스트 중 새 그룹관리자 API가 404
- **원인:** 사용자가 백엔드를 워크트리가 아닌 원본 repo 경로에서 띄우고 있었음
- **해결:** 원본 프로세스 종료 후 워크트리 경로에서 `.venv`/`.env` 심볼릭 링크 연결해 재기동
  → 프론트엔드 쪽 후속 이슈: [[projects/dna-sql-agent-web/issues/group-admin-entry-point-missing|group-admin-entry-point-missing]]

## 다음 할 일

- [ ] 백엔드 커밋 (기능 단위로 분리, 사용자 검토 후)
- [ ] `group-admin-design.md` §7 "정책 확정 이력"에 남겨둔 세부 구현 판단(그룹 매핑
      해제 시 처리, 커넥션 단독소유 판정 로직 등)이 실제 배포 전 최종 리뷰 필요
- [ ] 워크트리 `.venv`/`.env` 심볼릭 링크는 임시 조치 — 정식 워크트리 워크플로 문서화 검토

## 효과적이었던 프롬프트

```
아 시스템 관리자란 현재 그룹의 admin을 의미하는거야 추가적으로 다른 그룹들에
그룹 관리자 기능을 넣는거고
```
