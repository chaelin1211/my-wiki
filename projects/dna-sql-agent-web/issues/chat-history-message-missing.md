---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-05-20
resolved: true
root-cause: "isLikelyResponseText 휴리스틱이 단순 텍스트를 잘못 필터링"
related: []
tags: [chat, build-steps, rendering]
---

# 이전 대화 로드 시 단순 응답 메시지 누락

## 증상

이전 대화를 클릭해서 로드할 때 일부 어시스턴트 메시지가 화면에 표시되지 않음.
특히 "안녕하세요! 무엇을 도와드릴까요?" 같은 단순 한 줄 응답이 누락됨.

## 환경

- **재현 조건:** components 배열에 status/task 관련 컴포넌트만 있고, content가 짧은 단문인 메시지

## 시도한 것들

1. ✅ `lib/build-steps.ts` `buildStepsFromMessage` 코드 추적
2. ✅ `isLikelyResponseText` 조건이 원인임을 확인 후 제거

## 근본 원인

`buildStepsFromMessage`에서 `components` 처리 후 text step이 없을 때 `m.content`를 추가할지 판단하는 `isLikelyResponseText` 휴리스틱:

```ts
const isLikelyResponseText = m.content.includes('\n\n') ||
  (m.content.includes('\n') && m.content.length > 50) ||
  m.content.includes('**') ||
  m.content.includes('- ') ||
  m.content.includes('#')
```

단순 한 줄 텍스트는 이 조건에 하나도 해당하지 않아 조용히 드랍됨.

## 해결 방법

`isLikelyResponseText` 조건 제거. text step이 없으면(`!hasTextStep`) 무조건 `m.content`를 추가.
중복 방지는 `hasTextStep` 체크만으로 충분.

```ts
if (m.content && m.content.trim()) {
  const hasTextStep = steps.some(s => s.kind === 'text')
  if (!hasTextStep) {
    steps.push({ kind: 'text', id: `text-${convId}-${msgIdx}`, content: m.content })
  }
}
```

## 예방책

렌더링 관련 휴리스틱은 실제 데이터로 검증 필요. "단순 텍스트 = 상태 메시지"라는 가정은 잘못된 것.

## 관련 페이지

- [[knowledge/troubleshooting/message-rendering-heuristic-pitfall]]
