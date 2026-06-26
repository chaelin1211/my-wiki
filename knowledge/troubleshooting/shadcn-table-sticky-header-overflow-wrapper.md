---
type: troubleshooting
title: "shadcn/ui Table sticky 헤더가 overflow 래퍼 때문에 고정 안 됨"
tags: [css, tailwind, table, sticky, shadcn, react]
date: 2026-06-23
---

# shadcn/ui Table 사용 시 sticky 헤더가 동작하지 않음

## 증상

shadcn/ui `<Table>` 컴포넌트 안에서 헤더에 `sticky top-0`을 줬는데, 스크롤해도 헤더가 고정되지 않고 내용과 함께 밀려 올라간다.

```tsx
<div className="max-h-80 overflow-auto">
  <Table>
    <TableHeader>
      <TableRow>
        <TableHead className="sticky top-0 z-10 bg-muted">...</TableHead>  {/* 동작 안 함 */}
```

## 원인

shadcn/ui의 `Table`은 내부적으로 `<table>`을 스크롤 래퍼로 감싼다:

```tsx
// components/ui/table.tsx (shadcn 기본)
<div data-slot="table-container" className="relative w-full overflow-x-auto">
  <table ...>
```

이 `overflow-x-auto` 래퍼가 새로운 스크롤 컨테이너를 만들면서, `position: sticky`의 기준(스크롤 부모)을 바깥의 `max-h-80 overflow-auto`가 아니라 이 안쪽 래퍼로 가로챈다. 안쪽 래퍼는 세로 스크롤이 없으므로 sticky가 걸릴 대상이 없어 헤더가 고정되지 않는다.

## 해결

스크롤 컨테이너를 직접 제어해야 할 땐 shadcn `<Table>` 대신 plain `<table>`을 쓴다. (하위 `TableHeader`/`TableRow`/`TableCell` 등은 그대로 재사용 가능 — 래퍼를 만드는 건 `Table` 하나뿐)

```tsx
<div className="w-full overflow-auto" style={{ maxHeight: '20rem' }}>
  <table className="w-full caption-bottom text-sm">   {/* Table → plain table */}
    <TableHeader>
      <TableRow>
        <TableHead className="sticky top-0 z-10 bg-muted">...</TableHead>  {/* 고정됨 */}
```

추가 주의: sticky 헤더 배경은 **불투명**이어야 한다. `bg-muted/60`처럼 반투명을 쓰면 스크롤된 내용이 헤더 밑으로 비쳐 보인다 → `bg-muted` 사용.

## 예방책

- 스크롤 컨테이너 + sticky 조합에서 헤더가 안 붙으면, 중간에 `overflow-*`를 가진 래퍼가 끼어 있는지 DevTools로 확인. sticky는 가장 가까운 스크롤 조상을 기준으로 한다.
- 컴포넌트 라이브러리의 "편의 래퍼"가 레이아웃 가정을 깨는 대표 사례.

## 관련 페이지

- [[knowledge/troubleshooting/sticky-column-offset-mismatch]]
- 세션: [[projects/dna-sql-agent/sessions/2026-06-23-runsql-limit-notice-datatable]]
