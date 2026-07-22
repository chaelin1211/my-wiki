---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-07-07
resolved: true
root-cause: "IME 조합 중 Enter 이벤트를 조합 가드 없이 그대로 처리하여 handleCreate가 두 번 호출됨"
related: [[[knowledge/patterns/ime-composition-enter-guard]]]
tags: [react, ime, korean-input, dashboard]
---

# 대시보드 생성 시 한글 이름 입력 + Enter → 두 개 생성

## 증상

새 대시보드 다이얼로그에서 이름을 한글로 입력하고 Enter를 눌러 생성하면, 같은 이름의 대시보드가 두 개 생성됨. 영문 이름 입력 시에는 재현되지 않음.

## 환경

- **OS:** macOS (Chrome)
- **런타임:** Next.js / React (dna-sql-agent-web)
- **관련 패키지:** shadcn `Dialog`/`Input`
- **재현 조건:** IME(한글/일본어 등 조합형 입력기)로 이름 입력 후 Enter로 확정 겸 전송

## 시도한 것들

1. ✅ `git log` 로 유사 버그 이력 검색 — `chat-input.tsx`에 이미 동일 원인의 수정 커밋(`eac7d36 fix: 한글 IME 조합 중 엔터 전송 방지`)이 있었음을 확인
2. ✅ `components/dashboard-panel.tsx`의 새 대시보드 `Input`에는 그 가드가 적용되지 않았음을 확인

## 근본 원인

`components/dashboard-panel.tsx`의 새 대시보드 이름 `Input`의 `onKeyDown`이 `e.key === 'Enter'`만 검사하고 `isComposing`(IME 조합 중 여부)을 확인하지 않았음. 한글 조합 중 Enter를 누르면 "조합 확정용 Enter"와 "실제 전송 Enter" 두 개의 keydown 이벤트가 겹쳐 들어와 `handleCreate()`가 두 번 호출됨.

같은 리포지토리 안에 `chat-input.tsx`에서는 이미 이 문제를 겪고 고친 이력이 있었는데, 이후 추가된 대시보드 생성 다이얼로그에는 같은 가드가 적용되지 않아 재발함 — "IME Enter 가드"가 프로젝트 규칙(컴포넌트)으로 문서화·재사용되지 않고 개별 fix로만 남아있던 것이 재발 원인.

## 해결 방법

```tsx
onKeyDown={(e) => {
  // 한글/일본어 IME 조합 중 엔터는 조합 확정용이므로 생성하지 않는다.
  if ((e.nativeEvent as unknown as { isComposing?: boolean }).isComposing || e.keyCode === 229) return
  if (e.key === 'Enter') void handleCreate()
}}
```

`chat-input.tsx`의 기존 가드(`isComposing || e.keyCode === 229`)를 동일하게 적용.

## 예방책

- Enter로 제출/생성/커밋되는 텍스트 입력이 새로 생길 때마다 IME 조합 가드를 기본으로 포함할 것 → 공용 훅이나 유틸(`useEnterSubmit` 등)로 추출하면 재발 방지에 더 효과적
- 관련 일반 패턴 문서화: [[knowledge/patterns/ime-composition-enter-guard]]

## 관련 페이지

- [[knowledge/patterns/ime-composition-enter-guard]]
- PR: https://github.com/DnA-Platform-Development-Team/dna-sql-agent-web/pull/68
