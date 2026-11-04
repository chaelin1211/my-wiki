---
type: troubleshooting
project: dna-sql-agent
date: 2026-10-20
resolved: true
root-cause: "task 모드 상태 검사가 loop 모드 러너만 만드는 lease 테이블을 조회"
related: [decisions/051-collection-lease-table-loop-only]
tags: [sql-collection, task-mode, lease, schema, fresh-install]
---

# 새 DB에서 SQL 예제 AI 추가가 성공 토스트만 뜨고 생성되지 않음 — lease 테이블 없음

## 증상

```
File ".../dna/sql_collectors/routes.py", line 505, in sql_auto_collection_health
File ".../dna/sql_collectors/routes.py", line 332, in _collect_collection_runner_health
asyncpg.exceptions.UndefinedTableError: relation "public.background_worker_leases" does not exist
```

- SQL 예제 탭이 열려 있는 동안 `GET /api/v1/db/sql-examples/collection/health`가 500으로 반복 실패 (화면은 오류를 숨김)
- "AI로 SQL 예제 추가"를 누르면 "요청이 접수되었습니다" 성공 토스트가 뜨지만 작업이 생성되지 않음. 서버 로그에는 `sql_auto_collection error: relation "public.background_worker_leases" does not exist`

## 환경

- **런타임:** `python src/main.py` (Docker 기본), PostgreSQL
- **관련 설정:** `SQL_COLLECTION_EXECUTION_MODE` 미설정 = `task` (기본값)
- **재현 조건:** loop 모드를 한 번도 돌린 적 없는 새 DB에 배포

## 시도한 것들

1. ✅ 테이블 생성 위치 추적 — `schema.py`에 없고 `CollectionRunner.start()`의 `_ensure_runner_lease_table`에서만 생성, 러너는 loop 모드에서만 기동
2. ✅ 영향 범위 — 수집 시작 API가 작업 생성 전 같은 상태 검사(`_ensure_collection_runner_ready_or_raise`)를 거침. 예상 밖 예외라 200 + `status: "error"`로 응답 → 화면 성공 토스트
3. ✅ 9월 E2E에서 안 걸린 이유 — 검증 서버 DB에 loop 시절 생성된 테이블이 남아 있었음

## 근본 원인

task 모드 전환 때 상태 검사 판정만 모드별로 나누고, lease 조회 쿼리와 복구 훅은 모드와 무관하게 남김. 테이블은 loop 모드 러너 기동 시에만 생기므로 task 모드 새 DB에는 존재하지 않음.

## 해결 방법

task 모드에서 lease 조회와 복구 훅(러너 재기동)을 생략 (PR #185, [[decisions/051-collection-lease-table-loop-only]]).

```python
if execution_mode != "task":
    lease_row = await conn.fetchrow("SELECT ... FROM public.background_worker_leases ...")
...
if execution_mode != "task" and callable(recover_once):
    await recover_once("health-gate")
```

배포 전 급한 우회: 운영 DB에 `CREATE TABLE IF NOT EXISTS public.background_worker_leases (...)`로 빈 테이블만 만들어도 정상 동작.

## 예방책

- 앱 DB 테이블은 `schema.py`(서버 기동 시 `init_schema()`)에서만 만든다. 실행 중 생성 테이블은 새 설치에서만 터진다 → [[knowledge/troubleshooting/runtime-created-table-missing-on-fresh-db]]
- 빈 PostgreSQL에 `init_schema()`만 실행한 상태로 API를 호출하는 새 설치 검증을 둔다
- 모드 전환·기능 제거 시 판정뿐 아니라 조회·부수 동작(훅)까지 모드 게이트를 확인

## 관련 페이지

- [[knowledge/troubleshooting/runtime-created-table-missing-on-fresh-db]]
- [[sessions/2026-10-20-collection-health-task-mode-lease]]
