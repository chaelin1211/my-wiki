---
type: troubleshooting
project: dna-sql-agent
date: 2026-10-01
resolved: true
root-cause: "이벤트 루프 스레드에서 연 SQLite 연결을 보조 스레드에서 사용, SQLite 는 DB 단 타임아웃 없음"
related: [personal-dataset, vectorization, sqlite]
tags: [sqlite, asyncio, threading]
---

# 관계 FAQ 생성 시 SQLite 스레드 오류

## 증상

```
sqlite3.ProgrammingError: SQLite objects created in a thread can only be used in that same thread.
```
관계 그룹이 있는 개인 데이터셋에서 관계 FAQ(`doc_relation_faq`) 단계가 실패.

## 환경

- **런타임:** Python 3.10, sqlite 3.51 (`THREADSAFE=2`, multi-thread 모드)
- **재현 조건:** 테이블 간 관계가 있는 엑셀 업로드 → 관계 정보에 그룹 생성 → 관계 FAQ 단계 진입

## 시도한 것들

1. ✅ `_run_in_job_executor(_run_select_sync, conn, ...)` 로 재현 — 기본값은 같은 오류, `check_same_thread=False` 는 정상
2. ✅ 무한 재귀 쿼리로 타임아웃 재현 — 앱 `wait_for` 만으로는 쿼리가 계속 실행됨

## 근본 원인

- 오케스트레이터가 이벤트 루프 스레드에서 연결을 열고, 관계 FAQ 단계는 컬럼 메타데이터 fallback(`asyncio.to_thread`)과 검증 쿼리(전용 executor)를 다른 스레드에서 실행
- Oracle·Postgres 드라이버는 이 제한이 없어 개인 데이터셋(SQLite)에서 처음 드러남
- 추가로 SQLite 는 DB 단 타임아웃이 없어, 앱 제한 시간 초과 후에도 쿼리가 보조 스레드에서 돌고 그사이 메인 스레드가 연결을 닫을 수 있었음(multi-thread 모드에서 동시 사용 금지)

## 해결 방법

```python
sqlite3.connect(path, check_same_thread=False)           # 순차 사용 허용
db_conn.set_progress_handler(lambda: 1 if time.monotonic() > deadline else 0, 10_000)  # 쿼리 스스로 중단
```
쿼리 종료 후 `set_progress_handler(None, 0)` 로 해제. PR 백엔드 #172.

## 참고

- [[knowledge/troubleshooting/sqlite-connection-shared-across-asyncio-threads]]
