---
type: troubleshooting
title: "HTML Table sticky 컬럼 두 번째 열 위치 어긋남"
tags: [css, tailwind, table, sticky]
date: 2026-05-27
---

# HTML Table sticky 컬럼 두 번째 열 left 오프셋 틀어짐

## 증상

두 컬럼을 sticky로 고정할 때 두 번째 컬럼에 `left-[180px]`를 지정했는데, 스크롤 시 첫 번째 컬럼 위로 겹치거나 간격이 틀어짐.

## 원인

첫 번째 컬럼에 `min-w-[180px]`만 지정하면 내용에 따라 실제 렌더 너비가 180px를 초과할 수 있음. 두 번째 컬럼의 `left`는 픽셀 고정값이므로 실제 너비와 불일치 발생.

## 해결

첫 번째 컬럼의 너비를 정확히 고정:

```tsx
// ❌ 잘못된 방법
<TableHead className="sticky left-0 min-w-[180px]">사용자</TableHead>
<TableHead className="sticky left-[180px] min-w-[100px]">그룹</TableHead>

// ✅ 올바른 방법
<TableHead className="sticky left-0 w-[180px] min-w-[180px] max-w-[180px]">사용자</TableHead>
<TableHead className="sticky left-[180px] w-[100px] min-w-[100px] max-w-[100px]">그룹</TableHead>
```

셀 내용이 길면 잘려야 하므로 텍스트에 `truncate` 추가:

```tsx
<TableCell className="sticky left-0 w-[180px] min-w-[180px] max-w-[180px] overflow-hidden">
  <span className="block truncate">{email}</span>
</TableCell>
```

## 핵심

`w` + `min-w` + `max-w` 세트로 지정해야 HTML table에서 컬럼 너비가 정확히 고정됨.