---
type: knowledge
topic: troubleshooting
tags: [react-grid-layout, typescript, nextjs, react-19]
date: 2026-06-15
---

# react-grid-layout TypeScript 설정 트러블슈팅

## 문제 1: `import { Layout }` 타입 에러

react-grid-layout은 `export =` CommonJS 방식을 사용해 named import가 불가능.

```typescript
// ❌ 에러
import GridLayout, { type Layout } from 'react-grid-layout'

// ✅ 해결: 로컬 인터페이스 정의
import GridLayout from 'react-grid-layout'

interface LayoutItem {
  i: string; x: number; y: number; w: number; h: number
  [key: string]: unknown
}
```

## 문제 2: React 19 — children prop 에러

React 19 타입에서는 `children`이 컴포넌트 Props에 암묵적으로 포함되지 않음.
react-grid-layout의 `@types` 패키지가 이를 반영하지 않아 컴파일 에러 발생.

```typescript
// ✅ require 캐스팅으로 우회
const GridLayout = require('react-grid-layout') as React.ComponentType<Record<string, unknown>>
```

## 문제 3: onLayoutChange 타입 불일치

`onLayoutChange`의 파라미터 타입이 `Layout[]`인데, `setState`의 타입과 불일치.

```typescript
// ✅ 별도 핸들러로 감싸기
const handleLayoutChange = useCallback((layout: unknown[]) => {
  setPendingLayout(layout as LayoutItem[])
}, [])

<GridLayout onLayoutChange={handleLayoutChange as any} ... />
```

## 패턴 정리

- react-grid-layout `cols={12}`, `rowHeight={80}` 기본 설정
- `draggableHandle=".drag-handle"` — 특정 요소만 드래그 핸들로 지정 (차트 인터랙션 충돌 방지)
- `isDraggable={editMode}` — 보기/편집 모드 분리
- 컨테이너 너비는 `ResizeObserver`로 측정해 `width` prop에 전달
