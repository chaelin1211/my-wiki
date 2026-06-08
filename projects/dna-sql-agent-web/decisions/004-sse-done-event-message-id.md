---
type: decision-record
project: dna-sql-agent-web
date: 2026-05-26
status: accepted
superseded-by: ""
tags: [sse, bookmark, backend-contract]
---

# ADR-004: SSE done 이벤트에서 message_id 직접 수신

## 맥락

북마크 기능에서 `addBookmark` API에 `message_id`가 필요하다. 기존에는 SSE 스트리밍 완료 후 `getConversation`을 재호출(`patchBackendMessageIds`)해 메시지 ID를 인덱스 기반으로 매핑했다. 이 방식에는 두 가지 문제가 있다:

1. 비동기 타이밍 레이스: 재호출 완료 전에 사용자가 북마크 클릭 시 `backendMessageId` 없음 → 북마크 버튼이 안 보이거나 404
2. 인덱스 기반 매핑의 불안정성: 메시지 순서 가정

## 선택지

### 옵션 A: 기존 patchBackendMessageIds 유지
- **장점:** 프론트 단독 변경 없음
- **단점:** 타이밍 레이스 근본 해결 불가, 재호출 오버헤드

### 옵션 B: SSE done 이벤트에 message_id 포함 (채택)
- **장점:** `message_id`를 `isStreaming: false`와 동일 렌더 사이클에 세팅 가능 → 타이밍 레이스 제거
- **단점:** 백엔드 SSE 포맷 변경 필요

## 결정

**옵션 B를 선택한다.**

백엔드 SSE 종료 이벤트를 `data: [DONE]` → `data: {"type":"done","message_id":123,"conversation_id":"..."}` 로 변경 요청.

프론트는 신포맷 파싱 먼저 구현, `[DONE]` 문자열은 폴백으로 유지하여 백엔드 전환 전후 모두 동작.

## 근거

`message_id`와 `isStreaming: false`를 동일 React 상태 업데이트로 처리하면 React 18 자동 배칭에 의해 중간 상태(스피너) 없이 바로 북마크 버튼이 표시된다. 타이밍 레이스가 완전히 제거되고 `patchBackendMessageIds` 재호출도 불필요해진다.

## 결과

- `vanna-api.ts`: `onDone(messageId, conversationId)` 시그니처, `type === 'done'` 분기 추가
- `use-chat-stream.ts`: `onDone`에서 `backendMessageId` 즉시 세팅, `patchBackendMessageIds`는 null 폴백
- 백엔드 미적용 시: `[DONE]` 폴백 → `patchBackendMessageIds` 동작 (기존과 동일)
- `message_id`가 null인 응답(차트/아티팩트 없음)은 북마크 불필요하므로 문제 없음

## 참고 자료

- [[sessions/2026-05-26-bookmark-ux-sse-done-event]]
- `docs/sse-analysis.md` — 신 포맷 명세