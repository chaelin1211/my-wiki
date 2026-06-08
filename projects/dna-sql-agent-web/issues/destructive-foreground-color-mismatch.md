---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-05-20
resolved: true
root-cause: "--destructive-foreground이 --destructive와 동일한 빨간값으로 설정되어 있음"
related: []
tags: [toast, css, shadcn]
---

# destructive 토스트 글씨가 빨간색(레드 on 레드)으로 보임

## 증상

`variant: 'destructive'` toast가 표시될 때 글자가 빨간색으로 표시됨.
HTML 미리보기(흰 배경 + 빨간 글씨)와 다르게 실제 앱에서는 배경도 빨갛고 글씨도 빨간색이어서 가독성 없음.

## 환경

- **관련 파일:** `app/globals.css`, `components/ui/toast.tsx`
- **재현 조건:** 오류 toast 표시 시

## 시도한 것들

1. ✅ `--destructive-foreground`를 흰색(`oklch(1 0 0)`)으로 변경 → 흰 글씨 + 빨간 배경
2. ✅ toast variant를 `bg-background text-destructive`로 변경 → 배경 통일, 글씨만 빨간색 (최종)

## 근본 원인

`globals.css`에서 `--destructive-foreground`가 `--destructive`와 동일한 빨간값으로 잘못 설정됨.

```css
/* 잘못된 설정 */
--destructive: oklch(0.577 0.245 27.325);
--destructive-foreground: oklch(0.577 0.245 27.325); /* 동일값 → 레드 on 레드 */
```

shadcn 표준은 `--destructive-foreground`를 흰색으로 설정해 빨간 배경 위 흰 글씨를 표현함.

## 해결 방법

toast variant를 수정해 배경은 `bg-background`(흰/다크)로 통일하고 글씨만 `text-destructive`(빨간색)로 적용.

```tsx
// components/ui/toast.tsx
destructive: 'destructive group border-destructive bg-background text-destructive'
```

`--destructive` 색상도 디자인 기준에 맞게 갱신:
```css
/* 라이트 */
--destructive: #c6383a;
/* 다크 */
--destructive: #e05555;
```

## 예방책

shadcn 토큰 커스터마이징 시 `--destructive-foreground`는 반드시 배경과 대비되는 색으로 설정할 것.

## 관련 페이지

- [[decisions/002-toast-pattern-jsx-icon]]
