---
type: decision-record
project: dna-sql-agent
date: 2026-05-26
status: accepted
superseded-by: ""
tags: [sse, bookmark, message-id, middleware]
---

# ADR-003: SSE 종료 이벤트에 message_id 포함

## 맥락

프론트엔드가 북마크 생성(`POST /api/v1/bookmarks`) 시 `message_id`가 필요하다.
신규 메시지의 경우 DB `message_id`(BIGSERIAL)는 서버에서 INSERT 시점에 생성되며, 기존 SSE 스트림 어디에도 포함되어 있지 않았다.
그 결과 프론트엔드가 id 없이 요청하여 404가 지속 발생.

## 선택지

### 옵션 A: 기존 SSE 청크에 message_id 포함
- **장점:** 추가 이벤트 없이 기존 구조 유지
- **단점:** message_id는 ChatSaveHook(DB INSERT)이 완료된 이후에 생성되므로, 기존 청크가 전송되는 시점에는 존재하지 않음 → 구조적으로 불가

### 옵션 B: `[DONE]` 직전에 별도 message_saved 이벤트 추가
- **장점:** 기존 `[DONE]` 유지, 새 이벤트 타입 명확
- **단점:** 프론트가 처리할 이벤트 타입 증가

### 옵션 C: `[DONE]`을 JSON done 이벤트로 교체
- **장점:** 이벤트 수 동일, message_id + conversation_id를 하나의 완료 신호로 전달
- **단점:** 기존 `[DONE]` 문자열 체크 로직 수정 필요

## 결정

**옵션 C를 선택한다.**

```
data: {"type": "done", "message_id": 123, "conversation_id": "conv_abc"}
```

## 근거

- `SaveComponentsMiddleware`가 `[DONE]` 감지 시 `_save_components()`를 실행하여 이미 message row를 조회함 → 이 시점에 message_id 획득 가능
- 북마크 가능 컴포넌트(chart/artifact)가 있는 응답에서는 `component_buffer`가 항상 non-empty이므로 `_save_components()` 항상 실행됨
- 이벤트 수를 늘리지 않아 프론트엔드 처리가 단순함
- `message_id: null`로 컴포넌트 없는 응답도 일관된 포맷 유지

## 결과

- 프론트엔드는 `[DONE]` 문자열 체크 → `type === "done"` 체크로 변경 필요
- `message_id`를 북마크 생성 요청에 바로 사용 가능, 별도 API 호출 불필요
- `SaveComponentsMiddleware`에서 bytes 인코딩 필수 (`str` yield 시 TypeError)

## 참고 자료

- `src/dna/middlewares/save_components_middleware.py`
- `docs/sse-analysis.md`
