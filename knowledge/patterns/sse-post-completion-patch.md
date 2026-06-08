---
type: pattern
tags: [sse, streaming, react, state]
---

# SSE 완료 후 최소 패치 패턴

## 문제

SSE(Server-Sent Events) 스트리밍 완료 후 서버에서 전체 메시지를 재조회하면
SSE로 쌓인 클라이언트 state(steps, UI 상태)가 서버 응답으로 덮어써진다.

## 패턴

완료 후 필요한 필드만 최소로 패치하는 경량 함수를 별도로 분리한다.

```ts
// 나쁜 예: 전체 재조회 → SSE steps 덮어씀
onDone: () => loadMessages(convId)

// 좋은 예: 필요한 ID만 패치
onDone: () => patchBackendIds(convId)

async function patchBackendIds(convId: string) {
  const detail = await getConversation(convId)
  // 백엔드가 tool role 등 추가 메시지를 포함할 수 있으므로 필터 필수
  const msgs = detail.messages.filter(m => m.role !== 'tool')
  setState(prev => prev.map(c => {
    if (c.id !== convId) return c
    return {
      ...c,
      messages: c.messages.map((m, i) => ({
        ...m,
        backendId: m.backendId ?? msgs[i]?.id,
      }))
    }
  }))
}
```

## 주의

- 백엔드 메시지 배열에는 프론트가 무시하는 role(e.g., `tool`)이 포함될 수 있다.
- index 기반 매핑 시 **반드시 프론트와 동일한 필터링**을 적용해야 한다.
- 이 패턴은 북마크 ID 수집, 메시지 DB ID 동기화 등 "스트리밍 후 메타데이터 획득" 상황에 적합하다.

## 적용 사례

- `dna-sql-agent-web`: `patchBackendMessageIds` — SSE 완료 후 `backendMessageId` 패치