---
type: troubleshooting
tags: [css, flexbox, overflow, scroll, height]
date: 2026-07-03
---

# overflow-y-auto가 안 먹힘 — 스크롤이 아니라 조상 h-full 누락으로 클리핑되는 것

## 증상

`overflow-y-auto`를 준 스크롤 컨테이너인데도 스크롤이 전혀 안 되고, 내용이 그냥 잘려 보인다.
`overflow-y-auto`, `pointer-events`, z-index 등을 아무리 만져도 안 고쳐진다.

## 원인

CSS에서 `height: 100%`(Tailwind `h-full`)는 **부모가 definite(확정) height를 가질 때만** 자식에게
그 크기를 물려준다. flex 컨테이너의 `flex-1`도 마찬가지로, 그 아이템의 **부모가 flex 컨테이너일
때만** 효과가 있다.

```
A (flex h-dvh)                ← definite height
 └─ B (flex-1)                ← A가 flex라서 definite height 받음, 근데 B 자체 display는 안 물어봄
     └─ C (overflow-hidden)    ← B의 자식. B가 flex든 아니든 C는 flex item으로 취급 안 될 수 있음
                                  (B가 display:flex가 아니면 C는 그냥 block, 그래도 height는 받음
                                  — B 자체가 definite height라서)
         └─ D (flex flex-1)   ← 여기서 문제! D의 부모 C가 flex가 아니면 D의 flex-1은 무효.
                                  D에 h-full도 없으면 D는 height:auto로 붕 뜬다.
             └─ E (h-full overflow-y-auto)  ← D가 auto height라 E의 h-full도 붕 뜬 D 기준이라
                                                무의미. 콘텐츠가 넘쳐도 "스크롤할 고정 영역"이 없어서
                                                그냥 D가 커지고, 그 D를 담은 C(overflow-hidden)가
                                                그 넘친 부분을 잘라버림.
```

즉, **중간 조상 하나가 명시적 height 전달을 빠뜨리면**, 그 아래로는 전부 `height: auto`가 되어
버리고, 훨씬 위쪽 어딘가의 `overflow-hidden`이 그 넘친 콘텐츠를 조용히 잘라낸다. 스크롤 컨테이너
자체(`overflow-y-auto`)의 클래스는 멀쩡해 보이므로 원인 추적이 오래 걸린다.

특히 컴포넌트를 삭제/리팩토링할 때 잘 발생한다 — 예: `<Parent className="h-full">`가 자식을
감싸고 있었는데, `Parent`를 없애고 자식을 상위 레이아웃에 직접 꽂으면, 자식은 코드가 안 바뀌었어도
`h-full`의 기준점을 잃는다.

## 진단 방법

브라우저 devtools에서 스크롤이 안 되는 요소부터 위로 올라가며 **Computed 탭의 `height`**를 확인한다.
어딘가에서 `auto`(픽셀값이 아님)로 찍히는 지점이 범인이다. 그 요소의 직속 부모가 `display: flex`가
아니거나, 그 요소 자신에게 `h-full`/`flex-1`이 없는 경우가 대부분이다.

## 해결

체인이 끊긴 지점의 요소에 명시적으로 `h-full`(또는 부모를 `flex flex-col`로 만들어서 `flex-1`이
먹히도록)을 추가한다.

```tsx
// Before — 부모가 flex가 아니라서 flex-1이 무효, height:auto
<div className="flex flex-1 min-w-0">...</div>

// After — 명시적으로 높이를 못박음
<div className="flex flex-1 min-w-0 h-full">...</div>
```

## 예방책

- 컴포넌트를 삭제/재구성할 때, 그 컴포넌트의 className에 `h-full`/`flex`/`min-h-0`가 있었다면
  삭제 전에 자식이 그 계약에 의존하고 있는지 확인할 것(자식이 `flex-1`만 있고 `h-full`이 없다면
  높이 없는 부모 아래선 무너짐)
- `overflow-hidden` 컨테이너 안에서 "스크롤이 안 된다"는 리포트는 `overflow-*` 속성보다 먼저
  height 체인을 의심할 것
- 스크롤 가능한 영역을 만들 때는, 그 영역의 직속 부모부터 최상위 정의된 높이(`h-dvh` 등)까지
  중간에 `display:flex`가 아니거나 명시적 height가 빠진 조상이 없는지 체인 전체를 점검

## 관련 페이지

- [[knowledge/troubleshooting/overflow-y-auto-focus-ring-clip]] (같은 `overflow-y-auto` 영역이지만
  다른 증상 — focus ring 클리핑)
- 사례: [[projects/dna-sql-agent/issues/dashboard-transition-height-chain-flicker]]
