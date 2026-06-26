---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-06-09
resolved: true
root-cause: "로컬 conversation id(generateId())를 백엔드 API에 그대로 전달. 백엔드는 backendConversationId를 기대함"
related: []
tags: [conversation, api, id-mismatch, 404]
---

# 새 대화 생성 직후 제목 변경·삭제·핀 시 404 오류

## 증상

"새 대화" 버튼으로 생성한 대화에서 같은 세션 내에 제목 변경, 삭제, 핀 시도 시 API 404 응답.
앱을 새로고침하면 정상 동작.

## 환경

- **런타임:** Next.js (React)
- **관련 파일:** `hooks/use-conversations.ts`
- **재현 조건:** 새 대화 생성 직후(새로고침 없이) 제목 변경·삭제·핀 시도

## 시도한 것들

1. ✅ `handleRenameConversation`, `handleDeleteConversation`, `handlePinConversation` 내부에서 API에 전달하는 `id` 추적
2. ✅ 백엔드 로드된 대화는 `id === backendConversationId`라 우연히 정상 동작함을 확인

## 근본 원인

`handleCreateWithSystem`으로 새 대화 생성 시:
- 로컬 `id = generateId()` (랜덤 UUID)
- `backendConversationId = res.id` (백엔드 실제 ID)

`handleRenameConversation` 등이 `id`(로컬 UUID)를 API에 그대로 전달 → 백엔드가 알 수 없는 ID → 404.

백엔드에서 목록을 다시 불러오면 로컬 `id`가 백엔드 `id`로 덮어써지므로 새로고침 후에는 정상 동작.

## 해결 방법

각 핸들러에서 `conversationsRef.current`로 `backendConversationId`를 찾아 API에 전달.
`backendConversationId`가 없으면 (아직 백엔드 미저장) API 호출 스킵.

```ts
// handleRenameConversation
const conv = conversationsRef.current.find(c => c.id === id)
const backendId = conv?.backendConversationId
if (!backendId) return
await updateConversationTitle(backendId, title)

// handleDeleteConversation - setConversations 전에 미리 읽기
const backendId = conversationsRef.current.find(c => c.id === id)?.backendConversationId
...
if (!backendId) return
await deleteConversation(backendId)
```

`handleDeleteConversation`은 `setConversations` 호출 전에 `backendId`를 읽어야 타이밍 문제 방지.

## 예방책

- 프론트엔드 로컬 id와 백엔드 id가 다를 수 있는 패턴에서는 항상 `backendId`를 명시적으로 조회
- [[knowledge/troubleshooting/frontend-local-id-vs-backend-id]]

## 관련 페이지

- [[knowledge/troubleshooting/frontend-local-id-vs-backend-id]]
