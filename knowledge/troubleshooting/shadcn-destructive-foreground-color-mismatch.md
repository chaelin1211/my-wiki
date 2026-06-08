---
type: troubleshooting
date: 2026-05-20
resolved: true
root-cause: "--destructive-foreground을 --destructive와 동일한 빨간값으로 설정"
related: []
tags: [shadcn, tailwind, css-variables, toast]
---

# shadcn — destructive-foreground 색상 잘못 설정 시 레드 on 레드 발생

## 증상

shadcn `variant: 'destructive'` 토스트/버튼에서 텍스트가 빨간색으로 표시되거나 배경과 텍스트가 동일 색이 되어 가독성이 없어짐.

## 근본 원인

`globals.css`(또는 shadcn 초기화 시 생성되는 CSS)에서 `--destructive-foreground`를 `--destructive`와 동일한 빨간값으로 설정하면 발생.

```css
/* 잘못된 예 */
--destructive: oklch(0.577 0.245 27.325);
--destructive-foreground: oklch(0.577 0.245 27.325); /* ← 동일값 */
```

shadcn 컴포넌트는 `bg-destructive text-destructive-foreground` 조합을 사용하므로, foreground가 background와 같은 색이면 텍스트가 보이지 않거나 같은 색으로 표시됨.

## 해결 방법

**방법 1: foreground를 흰색으로 설정 (표준 shadcn 방식)**

```css
--destructive-foreground: oklch(1 0 0); /* 흰색 */
```

→ 빨간 배경 + 흰 텍스트

**방법 2: 컴포넌트 variant 변경 (배경 통일이 목적일 때)**

```tsx
// toast.tsx
destructive: 'destructive group border-destructive bg-background text-destructive'
```

→ 기본 배경 + 빨간 텍스트 (성공/오류 배경 통일 시 사용)

## 예방책

shadcn CSS 변수 커스터마이징 시 `*-foreground`는 항상 해당 배경과 대비되는 색으로 설정.

| 변수 | 역할 |
|---|---|
| `--destructive` | 배경색 (`bg-destructive`) |
| `--destructive-foreground` | 해당 배경 위 텍스트색 (`text-destructive-foreground`) |
| `text-destructive` | 기본 배경 위 빨간 텍스트 (직접 사용) |