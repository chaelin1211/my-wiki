---
type: troubleshooting
tags: [css, overflow, focus-ring, tailwind]
date: 2026-06-01
---

# overflow-y-auto 설정 시 자식 input focus ring 좌측 클리핑

## 증상

`overflow-y-auto` 컨테이너 안의 `<input>`, `<textarea>` 등 포커스 시 focus ring(box-shadow)이 좌측만 잘려 보임.

## 원인

CSS 스펙: `overflow-y`를 `visible` 이외 값으로 설정하면 `overflow-x`도 암묵적으로 `auto`로 변경된다.  
`overflow: auto`는 scroll container를 생성하고, 이 container의 경계에서 ink overflow(box-shadow 포함)를 클리핑한다.

`pr-2`처럼 우측 padding만 있을 경우 좌측 경계에 여유 공간이 없어 ring이 잘린다.

## 해결

스크롤 컨테이너에 focus ring 너비만큼 좌측 padding 추가.

```tsx
// shadcn focus ring은 ring-[3px] = 3px
<div className="overflow-y-auto pl-[3px] pr-2">
  ...
</div>
```

## 참고

- focus ring이 양쪽 모두 필요하면 `px-[3px]` 사용
- `pr-2`는 스크롤바 공간 확보용이므로 유지
