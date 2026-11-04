---
type: troubleshooting
tags: [html, frontend, react, form, date-input]
---

# `<input type="date">` — 없는 날짜는 화면엔 보여도 값이 빈 문자열

## 증상

- 생년월일 칸에 날짜를 넣었는데 "필수 입력" 버튼이 켜지지 않는다.
- 선택 항목인 날짜 칸에 이상한 날짜를 넣으면 오류 없이 "값 없음"으로 저장된다.
- 일(日) 칸에 `99` 를 치면 포커스 중에는 `99` 로 보이다가 칸을 벗어나면 `31` 로 바뀐다.

## 원인

브라우저(크롬 기준)는 날짜 칸이 **완전한 실제 날짜일 때만 `value` 를 채운다.** 연·월·일 중 하나가 비었거나, 그 달에 없는 날(예: 2월 31일, 11월 31일)이면 화면에 숫자가 보여도 `value === ''` 이다. 이때 `input.validity.badInput === true` 가 된다.

- 1월처럼 31일이 있는 달에서 일 칸에 `99` → 값은 `1990-01-31`(유효).
- 11월(30일까지)에서 `99` → 값은 빈 문자열, `badInput` true.
- 연도 칸은 최대 6자리까지 받아서, 숫자를 이어 치면 월·일로 넘어가지 않고 연도에 붙을 수 있다(자동화 테스트에서 특히).

## 해결

- **필수 날짜:** 버튼 활성 조건을 "값이 있음"으로 둔다. 화면에 날짜가 보여도 값이 비면 버튼이 꺼진 채 남는다.
- **선택 날짜:** 제출할 때 `validity.badInput` 을 함께 확인해 "다시 확인해주세요"로 막는다. 입력 이벤트는 날짜가 완성되지 않으면 안 올 수 있으니 제출 시점에 DOM 에서 읽는다.

```ts
export function hasBadDateInput(id: string): boolean {
  const input = document.getElementById(id)
  return input instanceof HTMLInputElement && input.validity.badInput
}
```

- 날짜 칸에서 엔터는 "입력 끝"의 뜻으로 누르는 경우가 많아, 폼이 바로 제출되지 않게 `onKeyDown` 에서 Enter `preventDefault` 를 고려한다.

## 확인 방법

헤드리스 확인은 **풀 크로미움 + `--lang=ko-KR`** 로 해야 한국어 칸 순서(연·월·일)가 맞는다. headless shell 은 로캘 처리가 달라 칸 순서가 어긋난다.

## 관련

- [[projects/dna-sql-agent/sessions/2026-10-19-auth-enhancement-signup-reset-account-management]]
