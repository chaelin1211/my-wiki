---
type: issue
project: dna-sql-agent-web
date: 2026-05-21
status: resolved
tags: [sse, streaming, chat, steps]
---

# sse-steps-overwritten-by-reload

## 문제

SSE 스트리밍 완료 후 차트·표 등 steps가 사라짐.

## 원인

`use-chat-stream.ts`의 `onDone` 콜백에서 `loadConversationMessages(currentActiveId)` 호출.
이 함수는 백엔드 API에서 메시지를 다시 불러와 steps를 재빌드하는데,
SSE로 실시간 누적된 chart/data/artifact steps와 API 재빌드 결과가 다를 수 있음.

결과적으로 SSE가 쌓은 steps가 API 재빌드 결과로 덮어써짐.

## 해결

`patchBackendMessageIds` 함수를 별도로 분리:
- steps 재빌드 없이 `backendMessageId` 필드만 패치
- tool role 메시지는 필터링 (백엔드 응답 index와 프론트 messages index 불일치 방지)

```ts
const patchBackendMessageIds = useCallback(async (convId: string) => {
  const detail = await getConversation(conv.backendConversationId)
  const relevantMsgs = (detail.messages ?? []).filter(m => m.role !== 'tool')
  setConversations(prev => prev.map(c => {
    if (c.id !== convId) return c
    const messages = c.messages.map((m, i) => ({
      ...m,
      backendMessageId: m.backendMessageId ?? relevantMsgs[i]?.id,
    }))
    return { ...c, messages }
  }))
}, [])
```

`onDone`에서 `loadConversationMessages` 대신 `patchBackendMessageIds` 호출.

## 교훈

SSE 스트리밍 완료 후 메시지 목록을 API로 재조회하면 안 된다.
필요한 정보(backendMessageId 등)만 최소로 패치하는 경량 함수를 따로 두어야 한다.
