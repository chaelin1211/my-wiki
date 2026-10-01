---
type: knowledge
category: troubleshooting
date: 2026-10-01
tags: [python, sqlite, asyncio, threading, timeout]
---

# asyncio 에서 SQLite 연결을 보조 스레드로 넘길 때 — check_same_thread 와 타임아웃

## 문제 패턴

이벤트 루프 스레드에서 `sqlite3.connect()` 로 연 연결을 `asyncio.to_thread`·`run_in_executor` 로
보조 스레드에서 쓰면 다음 오류가 난다.

```
sqlite3.ProgrammingError: SQLite objects created in a thread can only be used in that same thread.
```

Oracle·Postgres 드라이버는 이 검사가 없어서, 여러 DB 를 같은 코드로 다루면 SQLite 에서만 늦게 드러난다.

## 해결

1. **순차 사용이면 `check_same_thread=False`** — 매번 await 로 끝나기를 기다리며 스레드를 번갈아 쓰는 구조라면 안전하다
2. **동시 사용은 여전히 금지** — `sqlite3.connect(':memory:').execute('pragma compile_options')` 에 `THREADSAFE=2`(multi-thread) 면 한 연결을 두 스레드가 동시에 쓰면 안 된다
3. **앱 타임아웃만으로는 부족** — `asyncio.wait_for` 가 시간 초과해도 보조 스레드의 쿼리는 계속 돈다. 그사이 다른 스레드가 같은 연결을 쓰거나 닫으면 2번 위반이 된다. SQLite 는 DB 단 statement timeout 이 없으므로 progress handler 로 직접 끊는다

```python
deadline = time.monotonic() + timeout_sec
conn.set_progress_handler(lambda: 1 if time.monotonic() > deadline else 0, 10_000)
try:
    cur = conn.execute(sql)       # 초과 시 OperationalError: interrupted
finally:
    conn.set_progress_handler(None, 0)   # 다음 쿼리에 남지 않게 해제
```

## 확인 방법

무한 재귀 CTE(`WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM c) SELECT count(*) FROM c`)
로 제한 시간 초과 → `interrupted` → 같은 연결로 다음 쿼리 정상 → close 정상까지 확인한다.

## 출처

- [[projects/dna-sql-agent/issues/relation-faq-sqlite-cross-thread]]
