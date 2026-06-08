---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-05-26
resolved: true
root-cause: "SSE 완료 후 backendMessageId 세팅이 비동기라 타이밍 레이스 발생"
related: [decisions/004-sse-done-event-message-id]
tags: [bookmark, sse, timing]
---

# 채팅에서 바로 북마크 시 not found

## 증상

채팅 응답 직후 차트/아티팩트 북마크 버튼이 안 보이거나, 클릭 시 API에서 404 not found 반환.

## 환경

- **재현 조건:** SSE 스트리밍 완료 직후 즉시 북마크 클릭

## 시도한 것들

1. ❌ `isStreaming && backendMessageId == null` 조건으로 스피너 표시 → 신 백엔드에서 두 상태가 동일 렌더에 세팅되어 스피너가 노출되지 않음
2. ✅ `backendMessageId == null`만으로 스피너 조건 설정 + SSE `done` 이벤트에서 `message_id` 직접 수신

## 근본 원인

기존 흐름:
```
SSE [DONE] → onDone() → update(isStreaming: false) → patchBackendMessageIds() [비동기]
                                                         ↓ API 재호출 완료 후
                                                       backendMessageId 세팅
```

`patchBackendMessageIds`가 완료되기 전까지 `backendMessageId == null` → 북마크 버튼 미표시 또는 404.

## 해결 방법

SSE `done` 이벤트에 `message_id` 포함 (백엔드 요청):
```json
data: {"type": "done", "message_id": 123, "conversation_id": "conv_abc"}
```

프론트: `onDone(messageId, conversationId)`로 시그니처 변경, `messageId != null`이면 `update(isStreaming: false, backendMessageId: messageId)` 단일 상태 업데이트로 처리 → 타이밍 레이스 제거.

백엔드 미적용 시: `[DONE]` 폴백 → `patchBackendMessageIds` 동작 (기존과 동일).

## 예방책

- SSE 스트림에서 북마크에 필요한 ID를 직접 전달하는 계약 유지
- `backendMessageId` 세팅과 `isStreaming: false`는 항상 동일 상태 업데이트로 처리

## 관련 페이지

- [[decisions/004-sse-done-event-message-id]]
- [[sessions/2026-05-26-bookmark-ux-sse-done-event]]
