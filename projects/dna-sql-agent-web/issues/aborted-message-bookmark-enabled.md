---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-06-09
resolved: true
root-cause: "AbortError를 onDone으로 처리해 patchBackendMessageIds가 실행되고, 중단된 메시지에 backendMessageId가 설정되어 북마크 버튼이 활성화됨"
related: []
tags: [streaming, bookmark, abort]
---

# 스트리밍 중단 메시지의 차트 북마크 버튼 활성화 문제

## 증상

에이전트 응답 스트리밍 중 사용자가 중단(Cancel)하면, 화면에 남은 차트 컴포넌트의 북마크 버튼이 활성화된 채로 표시됨. 클릭 시 오류 발생 (해당 메시지가 DB에 저장되지 않았으므로).

## 환경

- **런타임:** Next.js (React)
- **관련 파일:** `lib/vanna-api.ts`, `hooks/use-chat-stream.ts`, `components/chat-message.tsx`
- **재현 조건:** 스트리밍 중 Cancel → 화면에 차트가 남아있을 때

## 시도한 것들

1. ✅ AbortError 발생 흐름 추적 → `vanna-api.ts` catch에서 `onDone(null, '')` 호출 확인
2. ✅ `onDone`에서 `messageId == null`이면 `patchBackendMessageIds` 실행 → backendMessageId 설정됨 확인

## 근본 원인

`lib/vanna-api.ts`에서 스트림 AbortError를 `callbacks.onDone(null, '')`으로 처리함.
→ `onDone` 핸들러가 `patchBackendMessageIds`를 호출
→ 백엔드에 부분 저장된 메시지가 있으면 `backendMessageId`가 설정됨
→ `StepBlock`에서 `backendMessageId != null`이면 북마크 버튼 활성화

## 해결 방법

`Message` 타입에 `isAborted?: boolean` 필드 추가.
`handleCancel`에서 중단된 메시지에 `isAborted: true` 설정.
`ChatMessage`에서 `message.isAborted`이면 `onBookmarkToggle`을 `undefined`로 대체하여 북마크 버튼/스피너 모두 비활성화.

```ts
// hooks/use-chat-stream.ts - handleCancel
m.isStreaming ? { ...m, isStreaming: false, isAborted: true, statusBar: undefined } : m

// components/chat-message.tsx
const effectiveOnBookmarkToggle = message.isAborted ? undefined : onBookmarkToggle
```

## 예방책

- 스트리밍 중단과 정상 완료를 명시적 플래그로 구분할 것
- AbortError를 onDone으로 처리하는 패턴은 완료와 중단을 구별하지 못하므로 주의
