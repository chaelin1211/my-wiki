---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-09
resolved: true
root-cause: "AsyncQdrantClient 로 일부만 전환해 coroutine 을 동기 결과처럼 .points 로 접근"
related: []
tags: [qdrant, asyncio, vector-db, migration]
---

# `AsyncQdrantClient` 전환 후 `'coroutine' object has no attribute 'points'`

## 증상

```
AttributeError: 'coroutine' object has no attribute 'points'
```

Qdrant 검색 호출 지점에서 발생. 동기 클라이언트일 때는 정상 동작하던 코드다.

## 환경

- `dna-sql-agent` — Qdrant 벡터 메모리 검색 경로
- `qdrant-client` 의 `QdrantClient` → `AsyncQdrantClient` 전환 작업 중

## 근본 원인

클라이언트만 async 로 바꾸고 **호출부를 전부 함께 바꾸지 않아서** 생긴 문제다.
`AsyncQdrantClient` 의 메서드는 coroutine 을 반환하는데, 호출부가 `await` 없이
동기 시절 그대로 `.points` 로 결과에 접근했다. coroutine 객체에는 그 속성이 없다.

부분 전환은 오류가 호출부 전체에 흩어져 나타나므로 한 곳을 고쳐도 다음 지점에서
같은 오류가 이어진다.

## 해결 방법

async 로 전면 전환하는 대신, **동기 `QdrantClient` 를 유지하고 `asyncio.to_thread()`
로 감싸** 이벤트 루프를 막지 않도록 했다.

```python
result = await asyncio.to_thread(client.query_points, ...)
```

호출부 인터페이스가 동기 그대로라 부분 전환으로 인한 불일치가 생기지 않는다.

## 예방책

- 동기 → async 클라이언트 전환은 **호출부 전체를 한 번에 바꿀 수 있을 때만** 착수할 것.
  중간 상태가 남으면 coroutine 이 값처럼 다뤄지는 오류가 산발적으로 터진다
- 블로킹 호출을 이벤트 루프에서 빼는 것이 목적이라면 `asyncio.to_thread()` 래핑이
  더 작은 변경으로 같은 효과를 낸다 → [[decisions/009-asyncio-to-thread-blocking-calls]]

## 관련 페이지

- [[projects/dna-sql-agent/sessions/2026-06-09-asyncio-threading-cancel-save]]
- [[decisions/009-asyncio-to-thread-blocking-calls]]
