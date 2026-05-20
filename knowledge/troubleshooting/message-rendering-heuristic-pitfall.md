---
type: troubleshooting
tags: [rendering, heuristic, frontend]
---

# 메시지 렌더링 휴리스틱의 함정

## 문제 패턴

스트리밍 메시지를 저장된 히스토리에서 재현할 때, "이 텍스트가 실제 응답인가?"를 판단하는 휴리스틱을 추가하면 정상 메시지가 드랍될 수 있다.

## 안티패턴 예시

```ts
// ❌ 마크다운 기호 유무로 "진짜 응답"을 판단
const isLikelyResponseText =
  content.includes('\n\n') ||
  content.includes('**') ||
  content.includes('- ') ||
  content.includes('#')

if (!hasTextStep && isLikelyResponseText) {
  steps.push({ kind: 'text', content })
}
// 단순 한 줄 텍스트 → 조용히 드랍됨
```

## 올바른 패턴

중복 방지는 "이미 같은 ID의 text step이 있는가"로만 판단.

```ts
// ✅ text step 유무만 확인
if (!hasTextStep) {
  steps.push({ kind: 'text', content })
}
```

## 교훈

- 텍스트 내용으로 "의미"를 판단하는 휴리스틱은 신뢰하지 말 것
- 중복 방지 로직은 ID나 상태 기반으로 처리할 것
- "단순 텍스트 = 상태 메시지"라는 가정은 틀렸다