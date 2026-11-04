---
type: troubleshooting
tags: [react, radix-ui, tooltip, frontend]
---

# Radix 툴팁을 강제로 열어 둘 때 hover·깜빡임 문제

알림 표시처럼 Radix `Tooltip` 을 `open` 으로 열어 둔 채, 마우스를 올리면 내용을 바꾸는 식으로 쓰면 아래 문제가 차례로 생긴다.

## 증상과 원인

1. **열어 둔 툴팁에 마우스를 올려도 아무 일이 없다.** Radix는 이미 열린 상태에서 hover가 와도 `onOpenChange(true)` 를 다시 부르지 않는다(값이 바뀌지 않았으므로). `onOpenChange` 로 hover를 감지하면 강제로 열린 동안에는 감지되지 않는다.
2. **hover로 직접 열면 나타났다가 바로 사라진다.** `onPointerEnter` 로 먼저 열고 나면, 이어서 Radix가 자기 열기 처리를 하면서 문서에 "다른 툴팁은 닫아라" 이벤트(`tooltip.open`)를 보낸다. 이미 열려 있던 자기 자신이 이 이벤트를 듣고 `onOpenChange(false)` 를 부른다. 이걸 hover 해제로 처리하면 툴팁이 닫힌다.
3. **작은 버튼 가장자리에서 빠르게 깜빡인다.** 툴팁(특히 꼬리)이 트리거 가장자리를 덮으면, 포인터가 툴팁 위로 올라가 트리거에 `pointerleave` 가 난다. 닫히면 다시 트리거 위라 `pointerenter` → 열림이 반복된다. Radix가 기본으로 해 주던 "툴팁 위로 옮겨 가도 유지" 처리가 직접 제어하면서 빠진 것이다.

## 해결

- 열림은 트리거의 `onPointerEnter`/`onPointerLeave`(+ `onFocus`/`onBlur`)와 강제 표시 여부로만 정하고, Radix의 `onOpenChange` 는 쓰지 않는다: `<Tooltip open={hovered || forced}>`.
- 툴팁 내용이 상호작용하지 않으면 `TooltipContent` 에 `pointer-events-none` 을 줘서 가장자리 깜빡임을 없앤다.
- 트리거가 `disabled` 가 되는 동안(로딩 등)에는 `pointerleave` 가 안 올 수 있으니 hover 상태를 초기화하고 툴팁을 닫는다.
- 강제로 열린 툴팁은 포털로 맨 위 레이어에 그려지므로, 모달이 열려 있는 동안에는 뒤쪽 툴팁을 숨긴다.

## 강조 색을 입힐 때

반투명 색(`bg-destructive/10`)을 본체와 꼬리에 그대로 쓰면 겹치는 부분이 진해진다. `color-mix(in oklab, <색> 10%, var(--background))` 처럼 불투명하게 섞은 색을 CSS 변수로 넘겨 본체·꼬리에 같이 쓴다. 꼬리(`TooltipPrimitive.Arrow`) 클래스를 바꿀 수 있게 래퍼에 `arrowClassName` 같은 옵션이 필요하다.

## 관련

- [[projects/dna-sql-agent/sessions/2026-10-12-tool-display-name-map-region-widget-refresh-error]] — 대시보드 위젯 새로고침 실패 `!` 툴팁
