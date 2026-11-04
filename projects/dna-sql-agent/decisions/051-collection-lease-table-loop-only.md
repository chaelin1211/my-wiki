---
type: decision-record
project: dna-sql-agent
date: 2026-10-20
status: accepted
superseded-by: ""
tags: [sql-collection, collection-runner, task-mode, lease, schema]
---

# ADR-051: 수집 러너 lease 테이블은 loop 모드 전용, task 모드는 참조하지 않음

## 맥락

SQL 예제 자동 수집은 2026-09-15에 lease 기반 폴링 러너(`loop`)에서 요청 워커가 직접 실행하는 방식(`task`, 기본값)으로 전환됐다. lease 테이블 `background_worker_leases`는 `CollectionRunner.start()`가 기동할 때만 만드는데, 러너는 `SQL_COLLECTION_EXECUTION_MODE=loop`일 때만 뜬다.

전환 때 상태 검사 판정만 모드별로 나누고, lease 조회 쿼리와 복구 훅(러너 재기동)은 모드와 관계없이 남았다. loop 모드를 돌린 적 없는 새 DB에 task 모드로 배포하자 테이블이 없어 상태 조회가 500을 내고, 수집 시작도 작업 생성 전에 실패했다.

## 선택지

### 옵션 A: `schema.py`에 lease 테이블 추가
- **장점:** 코드 변경 최소, 모드와 무관하게 오류 사라짐
- **단점:** task 모드에서 쓰지 않는 테이블을 모든 서버에 만듦. task 모드가 lease에 기대는 잘못된 의존이 그대로 남아, 활성 LLM이 없을 때 복구 훅이 lease 갱신만 하는 러너를 띄우는 동작도 유지됨
- **비용/노력:** 낮음

### 옵션 B: task 모드에서 lease 조회·복구 훅 생략
- **장점:** 전환 설계 의도(lease는 loop 롤백 경로 전용)와 일치. task 모드는 테이블을 읽지도 만들지도 않음
- **단점:** task 모드 상태 응답의 `lease_*` 필드가 항상 null (웹은 180초 넘은 pending 표시에만 사용, 동작 변화 없음)
- **비용/노력:** 낮음 (`routes.py` 두 군데)

### 옵션 C: 운영 DB에 테이블만 수동 생성
- **장점:** 배포 없이 즉시 복구
- **단점:** 새 설치마다 반복, 근본 해결 아님
- **비용/노력:** 매우 낮음, 일회성

## 결정

**옵션 B를 선택한다.** `_collect_collection_runner_health`는 `execution_mode != "task"`일 때만 lease를 조회하고, `_ensure_collection_runner_ready_or_raise`는 loop 모드에서만 복구 훅을 호출한다.

## 근거

task 모드에서 lease는 기능상 필요 없다. 작업 중복 실행은 작업 행의 원자적 `pending → running` 전환으로 막고, task 모드 비정상 판정의 원인은 수집 비활성화·활성 LLM 없음 같은 설정 문제뿐이라 러너 재기동으로 해결되지 않는다. 쓰지 않는 의존을 테이블로 메우기보다 의존 자체를 끊는 쪽이 맞다.

## 결과

- PR #185 (`fix/collection-health-task-mode`). 새 테스트 3건, 실제 PostgreSQL 새 DB에서 수정 전 오류 재현·수정 후 정상 확인
- loop 모드 동작은 변화 없음
- task 모드에는 작업 생존을 판단할 수단이 여전히 없음 → 경과 시간 기준 정리의 오판정은 별도 과제 ([[knowledge/patterns/job-liveness-owner-finalizes-reader-expires]])
- loop 경로 코드 완전 삭제 시 이 분기도 함께 정리

## 참고 자료

- `docs/collection-runner-orchestrator-migration.md` §10
- [[issues/collection-health-lease-table-missing-on-fresh-db]]
- [[sessions/2026-10-20-collection-health-task-mode-lease]]
