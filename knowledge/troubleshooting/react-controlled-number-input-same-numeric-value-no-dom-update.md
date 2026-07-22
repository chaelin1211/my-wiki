---
type: troubleshooting
tags: [react, controlled-input, dom, reconciliation]
---

# React 컨트롤드 number input이 "같은 숫자값"일 때 DOM이 갱신되지 않는 문제

## 증상

blur 시 입력값을 min/max/step에 맞춰 스냅(반올림)하는 숫자 입력 필드를 만들었는데, 사용자가 `0.3000000001` 같은 값을 입력하고 blur하면 상태(state)는 `0.3`으로 올바르게 갱신되는데도 화면(DOM)에는 여전히 사용자가 타이핑한 지저분한 문자열이 남아 있었다.

## 원인

React는 컨트롤드 인풋을 리렌더링할 때 새 `value` prop을 이전에 실제로 렌더링했던 값과 비교한다. 이 비교는 **문자열 동등성이 아니라, DOM에 이미 반영된 값과 새로 계산된 값이 "같다고 판단되면" DOM에 손대지 않는" 방식**으로 동작한다. `input[type=number]`의 경우 브라우저가 내부적으로 문자열을 숫자로 취급하기 때문에, `"0.3000000001"`이 이미 DOM에 있고 다음 렌더에서 계산된 값이 숫자로는 같은 `0.3`이더라도(혹은 문자열 포맷만 다르고 실질적으로 값이 같다고 인식되면) React가 실제 DOM text를 갱신하지 않는 경우가 생긴다. 결과적으로 state는 맞는데 화면 표시만 안 바뀌는 것처럼 보인다.

## 해결

state 업데이트에만 의존하지 말고, blur 핸들러 안에서 **DOM 엘리먼트의 `value`를 직접 명령형으로 설정**한다:

```tsx
const commit = (input: HTMLInputElement) => {
  const parsed = Number(input.value)
  const snapped = snapToStep(Number.isFinite(parsed) ? parsed : value, min, max, step)
  if (snapped !== val) {
    onChange(snapped)
  }
  // 문자열은 달라도 숫자값이 같으면 React가 DOM을 갱신하지 않는다.
  input.value = String(snapped)
}
```

즉 React의 선언적 렌더링에 맡기지 않고, 그 값을 표시해야 하는 정확한 시점(blur)에 ref/currentTarget을 통해 명령형으로 DOM을 동기화한다.

## 언제 이 패턴이 필요한가

- "타이핑 중에는 그대로 보여주고, blur/confirm 시에만 정규화(반올림, 포맷팅, clamp)하는" draft-state + commit-on-blur 패턴을 쓰는 숫자/텍스트 입력 전반
- 정규화 전후 값이 "실질적으로 같다고" 취급될 수 있는 모든 경우 (숫자 포맷 차이, trailing zero, 공백 트리밍 등)

## 관련

- [[projects/dna-sql-agent/sessions/2026-07-06-admin-pagination-dialog-fixes-and-perf]]
