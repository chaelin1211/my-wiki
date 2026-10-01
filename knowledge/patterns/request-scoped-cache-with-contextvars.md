---
type: pattern
tags: [python, asyncio, contextvars, cache, security, fastapi]
---

# ContextVar 요청 단위 캐시 — 수명은 "요청"이 아니라 "태스크"다

## 문제

한 요청 안에서 여러 레이어가 같은 값을 각자 DB 에서 조회하는 중복. 특히 권한처럼
**회수가 즉시 반영돼야 하는 값**은 TTL 캐시로 묶을 수 없다. "권한 뺏었는데 N 초간
계속 통과"가 생기기 때문이다.

전역 dict 도 안 된다 — 모든 요청·사용자가 공유해 A 의 권한이 B 에게 반환될 수 있다.

## 해결 패턴

`ContextVar` 에 dict 를 담아 요청 단위로 격리한다. `ContextVar` 자체는 캐시가 아니라
**dict 를 컨텍스트 단위로 격리해 담는 그릇**이다.

```python
_cache: ContextVar[dict | None] = ContextVar("perm_cache", default=None)

async def get_permissions(user):
    cache = _cache.get()
    if cache is None:
        cache = {}
        _cache.set(cache)
    key = (tuple(sorted(user.groups)), conn_name, system_name)
    if (hit := cache.get(key)) is not None:
        return hit
    result = await db_query(...)
    cache[key] = result
    return result
```

요청이 바뀌면 다시 조회하므로 권한 회수가 다음 요청부터 즉시 반영된다.

## 함정 1 — 수명이 태스크 단위다

`ContextVar` 는 **태스크** 단위로 격리된다. "요청 단위"가 되는 건 HTTP 에서 요청마다
태스크가 새로 생기기 때문이지, 프레임워크가 요청 경계를 알아서 지워주는 게 아니다.

**WebSocket 은 연결 하나가 루프로 여러 메시지를 처리한다 = 한 태스크.**

```python
while True:
    data = await websocket.receive_json()   # 메시지 2번째부터 이전 캐시가 그대로
    ...
```

권한 캐시라면 연결이 유지되는 몇 시간 동안 회수가 반영되지 않는다. 루프 시작에서
명시적으로 비워야 한다.

```python
while True:
    reset_request_caches()
    data = await websocket.receive_json()
```

같은 함정이 있는 곳: 롱폴링 루프, 백그라운드 워커의 작업 루프, 배치 처리 루프 —
**하나의 태스크가 여러 논리적 작업 단위를 처리하는 모든 구조.**

## 함정 2 — 전파는 단방향이다

```
부모에서 set() → 이후 생성된 자식 태스크에 복사됨    ✅ 보임
자식에서 set() → 부모로 돌아오지 않음                ❌ 안 보임
```

**"나중에 실행되니까 보이겠지"가 아니라 "컨텍스트 계보가 이어지나"** 로 판단해야 한다.
시간 순서가 아니라 생성 시점의 복사 관계다.

SSE 스트리밍처럼 엔드포인트에서 값을 담고 제너레이터에서 읽는 구조는 확인이 필요하다.
Starlette `StreamingResponse.__call__` 은 두 경로 모두 전파가 보장된다:

- ASGI spec ≥ 2.4: `await self.stream_response(send)` — 같은 태스크
- 그 미만: `task_group.start_soon(...)` — 새 태스크지만 **생성 시점에 현재 컨텍스트 복사**

부수 효과로 **병렬 태스크에서는 히트율이 떨어질 수 있다.** 캐시가 아직 비어 있을 때
자식들이 동시에 시작하면 각자 조회한 뒤 각자의 복사본에만 담는다. 정확성 문제는 아니다.

## 캐시 등록을 강제하기

캐시가 여러 모듈에 흩어지면, 새 캐시를 추가할 때 WebSocket 초기화를 빠뜨리기 쉽다.
**생성 함수를 거치게 해서 등록을 강제**한다.

```python
_registry: list[ContextVar] = []

def request_scoped_cache(name: str) -> ContextVar:
    var = ContextVar(name, default=None)
    _registry.append(var)     # 여기서 만든 것만 초기화 대상
    return var

def reset_request_caches() -> None:
    for var in _registry:
        var.set(None)
```

## 검증 포인트

**결과만 보고는 캐시 적중을 알 수 없다.** 캐시가 빗나가도 폴백 조회가 같은 답을 주므로
동작은 정상이고 절감만 안 된다. 조회 횟수를 세거나 HIT/MISS 를 찍어야 확인된다.

테스트로 남길 것:
- 요청 내 N 회 호출 → DB 1 회
- 요청이 바뀌면 다시 조회 (회수 즉시 반영)
- **한 태스크가 여러 작업을 처리할 때 리셋 없이는 재사용됨** (WS 회귀 방지)

## 관련 페이지

- [[knowledge/patterns/server-derives-scope-from-record-not-client-input]]
- [[projects/dna-sql-agent/decisions/029-conversation-system-scope-server-side]]
