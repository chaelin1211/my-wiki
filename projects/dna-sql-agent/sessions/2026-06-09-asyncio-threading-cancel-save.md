---
type: session-log
project: dna-sql-agent
date: 2026-06-09
duration: ~3h
focus: "asyncio 이벤트 루프 블로킹 해소 + 스트리밍 중단 시 사용자 메시지 저장"
tools-used: [claude-code]
outcome: success
---

# 2026-06-09 — asyncio 블로킹 해소 및 스트리밍 중단 저장

## 목표

1. 동시 대화 로딩 시 6~8초 지연 원인 파악 및 해결
2. 사용자가 스트리밍 중단 시 사용자 메시지가 유실되는 문제 해결
3. 사이드바 스트리밍 배지 UI 개선

## 수행한 작업

1. **asyncio 블로킹 원인 분석**
   - SentenceTransformer.encode(), QdrantClient.search(), psycopg2/oracledb 커넥션이 모두 동기 블로킹 → 이벤트 루프 점유
   - 동시 요청 시 첫 번째 요청이 루프를 잡으면 나머지가 대기

2. **`asyncio.to_thread()` 적용** (브랜치: `refactor/conversation-state-management`)
   - `src/dna/enhancers/retriever.py`: `_create_embedding` → `asyncio.to_thread(embed_query)`
   - `src/dna/vectorstores/qdrant_store.py`: `search()`, `fetch_table_metadata()` → `asyncio.to_thread`
   - `src/vanna/integrations/postgres/sql_runner.py`: 내부 `_run()` 함수 + `asyncio.to_thread`
   - `src/vanna/integrations/oracle/sql_runner.py`: 동일 패턴

3. **스트리밍 중단 감지 및 사용자 메시지 저장**
   - `src/dna/hooks/chat_save_hook.py`: `save_user_message()` standalone async 함수 추가
   - `src/vanna/servers/fastapi/routes.py`: `stream_completed` 플래그 + `try/finally` 패턴
     - 정상 완료: `stream_completed = True` → `after_message`에서 저장
     - 중단/에러: `finally`에서 `asyncio.create_task(save_user_message(...))`

4. **프론트엔드 배지 UI 개선** (브랜치: `feat/route-based-navigation`)
   - `components/conversation-list.tsx`: 배지 색상 → `bg-primary`, 위치 → 타이틀 앞으로 이동

5. **workflow 단락 경로 저장 여부 검토**
   - `/help`, `/status`, `/memories`, `/delete` 등 시스템 커맨드는 저장 안 함 → 의도적 설계
   - `DnaWorkflowHandler` 커스텀 케이스(삭제, 급여)는 모두 주석 처리 상태

## 핵심 결정

- **`asyncio.to_thread()` 채택 (AsyncQdrantClient 대신):** Qdrant 클라이언트를 비동기로 교체했다가 `'coroutine' object has no attribute 'points'` 오류 → 롤백 후 동기 클라이언트 + `to_thread` 패턴 확정
  → ADR: [[decisions/009-asyncio-to-thread-blocking-calls]]

- **`try/finally` 단절 감지 방식:** `db_base_count` 문제(사전 저장 시 중복 메시지) 때문에 중간 저장 대신 최종에만 저장하고 중단 시 finally에서만 사용자 메시지 저장
  → ADR: [[decisions/009-asyncio-to-thread-blocking-calls]]

## 배운 것

- Python async generator에서 클라이언트 disconnect는 `GeneratorExit`로 전파 → `finally` 블록이 항상 실행됨
- `asyncio.create_task()`는 `finally` 블록에서 `GeneratorExit` 상황에서도 안전하게 작동 (`await`는 불가)
- `db_base_count`는 `get_conversation()` 시점의 메시지 수를 baseline으로 삼아 `after_message`가 새 메시지만 저장하는 방식

## 문제 & 해결

- **문제:** `AsyncQdrantClient` 전환 후 `'coroutine' object has no attribute 'points'`
- **원인:** 클라이언트 인터페이스가 일부만 전환되어 awaitable 결과를 `.points` 접근
- **해결:** 동기 `QdrantClient` 유지 + `asyncio.to_thread()` 래핑
  → 이슈: [[issues/qdrant-async-client-partial-migration]]

- **문제:** 사전 저장 시 `db_base_count` 불일치로 LLM이 중복 사용자 메시지를 컨텍스트로 받음
- **원인:** `get_conversation()` 이후 사전 저장하면 `db_base_count`가 +1 되어 그 메시지를 건너뜀, 하지만 agent의 `add_message`가 또 추가해서 중복
- **해결:** 사전 저장 포기 → `finally` 블록에서만 저장

## 다음 할 일

- [ ] `refactor/conversation-state-management` 브랜치 PR 생성 및 머지
- [ ] `feat/route-based-navigation` 브랜치 PR 생성 및 머지
- [ ] workflow 차단 케이스 활성화 시 저장 로직 추가 (삭제/급여 필터)
- [ ] SQL Guard 그룹별 테이블 접근 제한 DB 연동
