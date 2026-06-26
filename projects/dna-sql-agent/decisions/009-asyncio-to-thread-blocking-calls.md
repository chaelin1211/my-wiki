---
type: decision-record
project: dna-sql-agent
date: 2026-06-09
status: accepted
superseded-by: ""
tags: [asyncio, performance, concurrency]
---

# ADR-009: 동기 블로킹 라이브러리 호출에 asyncio.to_thread() 사용

## 맥락

동시 대화 로딩 시 6~8초 지연이 발생했다. 원인 분석 결과:
- `SentenceTransformer.encode()` — CPU-bound 동기 블로킹
- `QdrantClient.search()` / `scroll()` — 동기 I/O 블로킹
- `psycopg2.connect()` / `oracledb.connect()` — 동기 DB 커넥션

FastAPI는 async 이벤트 루프 기반이라 이 호출들이 루프를 직접 점유하면 다른 요청이 대기한다.

## 선택지

### 옵션 A: asyncio.to_thread() 래핑 (동기 클라이언트 유지)
- **장점:** 클라이언트 교체 없이 적용 가능, 스레드풀로 이벤트 루프 해방
- **단점:** GIL로 인해 Python CPU-bound 작업은 실제 병렬 실행 안 됨 (I/O bound에는 충분)
- **비용/노력:** 낮음 — 각 호출 지점만 수정

### 옵션 B: AsyncQdrantClient 등 비동기 클라이언트로 교체
- **장점:** 네이티브 async 지원
- **단점:** API 인터페이스가 달라 부분 전환 시 `'coroutine' has no attribute 'points'` 류 오류 발생. Qdrant Python SDK의 async client는 동기 대비 일부 메서드 시그니처 차이 존재
- **비용/노력:** 높음 — 클라이언트 교체 + 전체 호출 스택 검증 필요

### 옵션 C: run_in_executor 직접 사용
- **장점:** 커스텀 Executor 지정 가능
- **단점:** `asyncio.to_thread()`와 사실상 동일한 기능, 문법만 더 장황함 (Python 3.9+에서 `to_thread`가 권장)
- **비용/노력:** 낮음

## 결정

**옵션 A — `asyncio.to_thread()` 래핑을 선택한다.**

## 근거

AsyncQdrantClient 전환을 시도했다가 `'coroutine' object has no attribute 'points'` 오류로 롤백했다. 현재 Qdrant 버전과 코드베이스의 의존 관계를 전부 검증할 시간이 없고, I/O 블로킹 해소에는 `to_thread`로 충분하다. SentenceTransformer는 GIL 때문에 진정한 병렬은 아니지만, 이벤트 루프 블로킹만 해소해도 다른 요청이 처리될 수 있어 체감 응답성이 개선된다.

## 결과

- **트레이드오프:** 스레드풀 스위칭 오버헤드 소폭 증가 (수 마이크로초, 무시 가능)
- **영향 파일:**
  - `src/dna/enhancers/retriever.py`
  - `src/dna/vectorstores/qdrant_store.py`
  - `src/vanna/integrations/postgres/sql_runner.py`
  - `src/vanna/integrations/oracle/sql_runner.py`
- **재검토 시점:** Qdrant Python SDK 메이저 버전 업그레이드 시 비동기 클라이언트 재검토

## 참고 자료

- Python docs: `asyncio.to_thread()` (3.9+)
- 관련 세션: [[sessions/2026-06-09-asyncio-threading-cancel-save]]
