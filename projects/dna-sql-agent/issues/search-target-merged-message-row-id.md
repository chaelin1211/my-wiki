---
type: troubleshooting
project: dna-sql-agent
date: 2026-10-08
resolved: true
root-cause: "웹이 응답의 여러 messages 행을 한 말풍선으로 합치며 첫 행 id만 남겨, 서버가 가리킨 최종 답변 행을 찾지 못함"
related: [bookmark-component-row-mismatch-404]
tags: [search, id-mismatch, react, chat-history]
---

# 검색 결과로 연 대화가 답변 일치 위치로 이동하지 않음

## 증상

전체 대화 검색에서 질문에는 없고 답변에만 있는 단어로 검색한 결과를 누르면, 대화는 열리지만 해당 답변으로 스크롤되지 않고 강조도 없음. 오류 메시지 없음.

## 환경

- **관련 패키지:** dna-sql-agent-web (`components/chat-view.tsx`, `hooks/use-conversations.ts`), dna-sql-agent (`src/dna/chat/search.py`)
- **재현 조건:** 도구를 호출한 응답(대부분의 SQL 답변)에서, 검색어가 최종 답변 본문에만 있을 때

## 시도한 것들

1. ✅ 개발 DB 집계로 영향 범위 확인 — 응답 240,822건 중 236,978건(98%)이 assistant 행 여러 개(도구 호출 행 + 최종 답변 행)로 저장됨.
2. ✅ 웹 이동 로직 확인 — `messages.findIndex(m => m.backendMessageId === scrollToMessageId)`가 못 찾으면 `if (targetIndex < 0) return`으로 조용히 종료.

## 근본 원인

`ChatSaveHook`은 한 응답을 도구 호출 행·도구 결과 행·최종 답변 행으로 나눠 저장한다. 웹은 대화를 불러올 때 연속된 assistant 행을 한 말풍선으로 합치면서 `backendMessageId`에 첫 행(도구 호출 행) id만 남긴다. 검색 SQL의 `first_message_id`는 실제로 일치한 행(대개 최종 답변 행)이라 화면 어디에도 같은 id가 없다.

## 해결 방법

합친 말풍선의 각 단계에는 이미 원래 행 id(`sourceMessageId`)가 붙어 있다(9/22 북마크 404 수정 때 추가). 이동 대상·현재 매치·강조 판정을 "말풍선 id 또는 단계 중 하나의 원래 행 id와 같으면 이 말풍선"으로 바꿈.

```ts
export function ownsBackendMessageId(message: Message, backendMessageId: number): boolean {
  return (
    message.backendMessageId === backendMessageId ||
    (message.steps?.some((step) => step.sourceMessageId === backendMessageId) ?? false)
  )
}
```

서버 응답 계약(`first_message_id` = 실제 일치 행)은 그대로 유지. 웹 #100 `9ae4cad`.

## 예방책

- 화면 항목 id와 저장 행 id를 같은 것으로 가정하는 비교(`=== backendMessageId`)를 새로 쓰지 말고, 행 id로 화면 항목을 찾을 때는 포함 관계로 찾는다.
- 대화 메시지 페이징을 도입하면 대상 행이 아직 로드되지 않을 수 있으므로 "대상 주변 불러오기"(응답 단위 경계)가 필요하다.
- 같은 원인의 다른 증상: 접힌 도구 호출 설명 글이 검색·일치 수에 포함되어 "검색에는 나오는데 열면 일치 없음"이 생김(미해결).

## 관련 페이지

- [[knowledge/troubleshooting/merged-rows-single-id-loses-child-location]]
- [[issues/bookmark-component-row-mismatch-404]]
- [[sessions/2026-10-08-conversation-search-review-and-in-chat-find]]
