---
type: session-log
project: dna-sql-agent
date: 2026-10-20
duration: 
focus: "task 모드 SQL 예제 생성 실패(lease 테이블 없음) 수정, 수집 작업 정리 구조 분석"
tools-used: [claude-code, docker, pytest, gh]
outcome: success
---

# 2026-10-20 — task 모드 SQL 예제 생성 실패(lease 테이블) 수정과 수집 작업 정리 구조 분석

## 목표

운영 서버 로그의 `UndefinedTableError: relation "public.background_worker_leases" does not exist` 원인을 찾고 고친다. 이어서 task 모드 SQL 예제 자동 수집(SQL 예제 탭 "AI로 SQL 예제 추가")의 남은 문제를 정리한다.

## 수행한 작업

1. 원인 추적 — `background_worker_leases`는 `schema.py`에 없고 `CollectionRunner.start()`(`_ensure_runner_lease_table`)에서만 생성됨. 러너는 `SQL_COLLECTION_EXECUTION_MODE=loop`(롤백용)일 때만 뜨고 기본값은 `task`라, loop를 돌린 적 없는 새 DB에는 테이블이 없음.
2. 영향 범위 확인 — 상태 조회 API(`/sql-examples/collection/health`)뿐 아니라 수집 시작 API도 작업 생성 전 같은 상태 검사를 거쳐 실패. 예상 밖 예외라 200 + `status: "error"`로 응답, 화면은 성공 토스트를 띄우고 작업은 생성되지 않음.
3. 지식화 탭과 구분 — 지식화의 `SQL Examples`는 이미 저장된 예제를 벡터화만 하는 단계라 이 문제와 무관. Tables/Columns/FAQ는 추출·LLM 생성·벡터화를 한 번에 하는데 SQL 예제만 생성이 SQL 예제 탭으로 분리돼 있음.
4. 이력 확인 — 9월 task 모드 전환(Phase 4)에서 판정만 모드별로 나누고 lease 조회 쿼리와 복구 훅은 그대로 둠. E2E 서버에는 loop 시절 테이블이 남아 있어서 드러나지 않음.
5. 수정 — `routes.py`에서 task 모드면 lease 조회를 건너뛰고 복구 훅(러너 재기동)도 호출하지 않음 → [[decisions/051-collection-lease-table-loop-only]]
6. 검증 — 새 테스트 3건(`tests/sql_examples/test_collection_health_execution_mode.py`), 수정 전 코드에서 task 모드 2건 실패 확인. Docker PostgreSQL에 `init_schema()`만 실행한 새 DB에서 HTTP 호출로 수정 전 오류 재현·수정 후 정상 동작 확인. 웹 화면이 lease 값 null을 "러너 비정상"으로 보지만 180초 넘은 pending 표시에만 쓰여 영향 없음 확인.
7. 문서 — `docs/collection-runner-orchestrator-migration.md`에 §10 후속 수정 추가, F13("lease 테이블 사용처 없음") 정정, 남은 과제 기록 후 분석 오류 정정.
8. PR #185 생성 (`fix/collection-health-task-mode`, 커밋 4개: fix·test·docs 2개).
9. task 모드 멀티 워커·작업 정리 구조 분석 (아래 "배운 것"·"다음 할 일").

## 핵심 결정

- **lease 테이블은 loop 모드 전용, task 모드는 읽지도 만들지도 않음:** `schema.py`에 테이블을 추가하는 방법은 쓰지 않는 테이블을 모든 서버에 만드는 셈이라 제외. task 모드 비정상 원인은 설정 문제(수집 비활성화·활성 LLM 없음)뿐이라 러너 재기동도 무의미.
  → ADR: [[decisions/051-collection-lease-table-loop-only]]

## 배운 것

- lease 테이블은 loop 모드에서 여러 워커 중 수집 루프 하나만 돌리기 위한 담당 워커 기록(등록·하트비트·담당권 인계·죽은 워커 작업 회수·워치독 감시). task 모드에는 상주 루프가 없고, 중복 실행은 작업 행 `pending → running` 원자적 전환(`_claim_job_by_id`)으로 막음.
- task 모드에는 주기적인 정리 배치가 없음. 오래된 작업은 ① 서버 기동 시 1회(`main.py` 경로 60초, `dna.app.lifecycle` 경로 600초) ② 같은 시스템 수집 시작 요청 시(600초)에만 경과 시간 기준으로 `error` 마감. 작업 생존과 무관한 시점에 시간으로 짐작하는 구조라 "오래 걸리는 정상 작업 실패 처리"와 "죽은 작업이 기준 시간 동안 재수집 막음"이 항상 함께 생김.
- 대상 DB 수집 함수(`oracle_collector` 등)가 동기 함수인데 이벤트 루프에서 바로 실행됨. 생존 신호나 전체 타임아웃을 넣으려면 먼저 `asyncio.to_thread`로 옮겨야 함.
- 같은 시스템 동시 수집 요청은 job 생성 트랜잭션의 `pg_advisory_xact_lock('sql_collection:{system_id}')`로 직렬화되어 중복 생성되지 않음.
- 서버 기동 코드가 `src/main.py`(Docker 기본)와 `src/dna/app/lifecycle.py` 두 벌이고 정리 기준·복구 훅 등록이 서로 다름.
- 실행 중 생성되는 테이블은 기존 환경 E2E로는 못 잡고 새 DB에서만 드러남 → [[knowledge/troubleshooting/runtime-created-table-missing-on-fresh-db]]

## 문제 & 해결

- **문제:** 새 DB에 task 모드로 배포한 서버에서 SQL 예제 AI 추가가 성공 토스트만 뜨고 생성되지 않음, 상태 조회 500 반복.
- **원인:** task 모드 상태 검사·복구 훅이 loop 전용 lease 테이블을 참조.
- **해결:** task 모드에서 lease 조회·복구 훅 생략 (PR #185).
  → 이슈: [[issues/collection-health-lease-table-missing-on-fresh-db]]

## 다음 할 일

- [ ] PR #185 리뷰·머지 후 운영 배포
- [ ] 수집 시작 시 예상 밖 오류도 실패로 응답·표시 (지금은 200 + `status: "error"` → 화면 성공 토스트)
- [ ] 작업 정리를 시간 기준에서 사실 기준으로: 대상 DB 수집 함수 `to_thread` 이동 → 작업 행 생존 신호 기록 → `run_job` 전체 타임아웃(`wait_for`, 마감은 바깥 래퍼) → 수집 시작·상태 조회·이력 조회 API에서 신호 끊긴 작업 마감 → 기동 시 시간 기준 정리 삭제 → [[knowledge/patterns/job-liveness-owner-finalizes-reader-expires]]
- [ ] (검토) `schema.py` 관리 — "앱 DB 테이블은 schema.py에서만" 검사 테스트, 빈 DB 설치 테스트, `init_schema()` advisory lock, 이후 버전 번호 마이그레이션
- [ ] (검토) 서버 기동 코드 두 벌(`main.py`·`lifecycle.py`) 통합
- [ ] 기존 깨진 테스트 `tests/sql_examples/test_sql_collectors_routes.py` 정리 (삭제된 `_build_skippable_completed_progress` import)

## 효과적이었던 프롬프트

```
근데 task 모드에서 그 테이블을 참고하는 이유가 뭐야? 기능상 분리 되어있는거 같은데
너가 저걸 개발했다고 생각하고 내 말에 대답해봐
```
