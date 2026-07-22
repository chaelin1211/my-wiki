---
type: pattern
tags: [react, ime, korean-input, japanese-input, forms]
---

# IME 조합 중 Enter 가드 (한글/일본어 입력 + Enter 제출 폭주 방지)

## 문제

한글·일본어 등 조합형 입력기(IME)로 텍스트를 입력하는 중 Enter를 누르면, 브라우저가 "조합 확정용 Enter"와 "실제 키 입력 Enter"를 별도의 `keydown` 이벤트로 발생시킬 수 있다. `onKeyDown`에서 `e.key === 'Enter'`만 검사해 제출·생성·커밋 로직을 실행하면 이 두 이벤트가 겹쳐 핸들러가 두 번 호출된다 (예: 대시보드/항목이 두 개 생성됨, 메시지가 잘리거나 중복 전송됨).

## 해결 패턴

`onKeyDown` 핸들러 맨 앞에서 조합 중 여부를 확인하고 조합 중이면 즉시 return.

```tsx
onKeyDown={(e) => {
  // IME 조합 중 엔터는 조합 확정용이므로 무시한다.
  if (e.nativeEvent.isComposing || e.keyCode === 229) return
  if (e.key === 'Enter') {
    handleSubmit()
  }
}}
```

- `isComposing`: 표준 `KeyboardEvent` 속성. React의 합성 이벤트에서는 `e.nativeEvent.isComposing`으로 접근.
- `keyCode === 229`: 일부 브라우저(특히 구형 Safari/일부 조합 시나리오)에서 `isComposing`이 정확히 반영되지 않을 때의 폴백.
- 두 조건을 OR로 함께 체크하는 것이 안전.

## 적용 시점

Enter 키 하나로 "제출/생성/이름 변경 확정" 같은 부수효과(side effect, 특히 API 호출)를 트리거하는 모든 입력 필드에 기본으로 적용해야 한다. 단순 로컬 상태 변경(예: 편집 모드 진입/이탈)만 하는 경우는 영향이 적지만, 그래도 습관적으로 넣는 편이 안전.

## 재발 이력

- `dna-sql-agent-web`의 `chat-input.tsx`에서 최초 발견·수정 (2026-07-01)
- 이후 별도로 추가된 `dashboard-panel.tsx`의 새 대시보드 생성 입력창에 같은 가드가 누락되어 재발 (2026-07-07) → [[projects/dna-sql-agent-web/issues/dashboard-create-korean-ime-enter-duplicate]]
- 재발 원인은 이 가드가 프로젝트 공용 규칙/컴포넌트로 추출되지 않고 개별 컴포넌트에 인라인으로만 존재했기 때문. Enter-to-submit 텍스트 입력이 여러 곳에 있다면 `useEnterSubmit(onSubmit)` 같은 공용 훅으로 추출하는 것을 고려.

## 관련 페이지

- [[projects/dna-sql-agent-web/issues/dashboard-create-korean-ime-enter-duplicate]]
