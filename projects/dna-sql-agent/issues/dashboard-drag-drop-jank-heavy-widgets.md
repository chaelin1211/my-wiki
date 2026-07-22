---
type: troubleshooting
project: dna-sql-agent
date: 2026-07-09
resolved: true
root-cause: "(1) 드래그 중 매 프레임 전체 위젯 리렌더 (2) 드롭 재배치 애니메이션에 GPU 레이어 승격 누락 (3) 그리드 라이브러리에 넘기는 설정 props가 매 렌더 새 참조"
related: [projects/dna-sql-agent-web]
tags: [react, performance, react-grid-layout, dashboard]
---

# 대시보드 편집 모드 드래그·드롭 시 무거운 위젯(지도) 버벅임

> 새 이슈 파일명: `dashboard-drag-drop-jank-heavy-widgets.md`

## 증상

지도 위젯이 많은 대시보드에서 편집 모드로 위젯을 드래그하거나 드롭할 때 화면이
버벅임. 특히 마우스를 뗀(드롭) 직후 위젯이 제자리에 들어갈 때까지 지연/끊김이
체감됨.

## 환경

- **OS:** -
- **런타임:** Next.js, React
- **관련 패키지:** react-grid-layout (`/core` 서브패스, `gridConfig`/`dragConfig`/
  `constraints` 커스텀 API 사용)
- **재현 조건:** 지도(Leaflet) 등 렌더 비용이 큰 위젯이 여러 개 있는 대시보드를
  편집 모드로 드래그

## 시도한 것들

1. ✅ **드래그 중 리렌더** — `GridLayout`의 `onLayoutChange`가 드래그 프레임마다
   호출 → `setPendingLayout` → `DashboardDetail` 전체 리렌더 → `visibleWidgets.map()`
   전체가 매번 새로 그려짐. `DashboardWidget`이 `React.memo`로 감싸져 있지 않았고,
   `onRemove` prop으로 내려가는 `handleRemoveWidget`도 매 렌더 새 함수라 메모가
   있었어도 무력화됐을 것.
   → `DashboardWidget`을 `React.memo`로, `handleRemoveWidget`을 `useCallback`으로.
   드래그는 x/y만 바꾸고(리사이즈 비활성) `chartHeight`/`activePreset`은 숫자
   프리미티브라 값 비교로 안전하게 스킵됨.

2. ✅ **드롭 순간 스터터** — `react-grid-layout` 기본 CSS 확인:
   ```css
   .react-grid-item.cssTransforms { transition-property: transform, width, height; }
   .react-grid-item.react-draggable-dragging { transition: none; will-change: transform; }
   ```
   `will-change: transform`이 **드래그 중인 위젯에만** 붙어 있어서, 드롭 후
   재배치(compaction)로 움직이는 다른 위젯들은 GPU 레이어 승격 없이 `transform`
   전환이 실행됨 → 무거운 내용(지도)이 매 프레임 다시 그려짐
   → `.react-grid-item` 전체에 `will-change: transform` 추가(globals.css)

3. ✅ **드롭 시 여전한 지연** — `GridLayout`에 넘기는 `gridConfig`/`dragConfig`/
   `constraints`/`resizeConfig`가 모두 인라인 객체/배열 리터럴이라 매 렌더 새
   참조. 실제 값이 안 바뀌어도 라이브러리가 "바뀐 것"으로 볼 여지가 있어
   불필요한 내부 재계산 가능성.
   → `useMemo`(`gridConfig`, `dragConfig`) / 모듈 스코프 상수
   (`GRID_CONSTRAINTS`, `RESIZE_CONFIG_DISABLED`)로 참조 고정

## 근본 원인

React 리렌더 최적화(자식 메모이제이션)와 CSS 컴포지팅 최적화(GPU 레이어 승격)
두 계층 모두에서 "실제로 바뀐 것만 다시 계산/그리기"가 안 지켜지고 있었음.
드래그앤드롭처럼 고빈도 이벤트가 발생하는 상호작용에서는 이 두 계층을 같이
점검해야 진짜 원인을 찾을 수 있음(리렌더만 고쳐서는 드롭 스터터가 안 없어짐).

## 해결 방법

`components/dashboard-widget.tsx`:
```ts
export const DashboardWidget = memo(function DashboardWidget({ ... }) { ... })
```

`components/dashboard-detail.tsx`:
```ts
const handleRemoveWidget = useCallback((widgetId: string) => { ... }, [])
const gridConfig = useMemo(() => ({ rowHeight, cols, margin: [...] }), [rowHeight, cols])
const dragConfig = useMemo(() => ({ enabled: editMode, handle: '.drag-handle' }), [editMode])
// GRID_CONSTRAINTS, RESIZE_CONFIG_DISABLED는 모듈 스코프 상수
```

`app/globals.css`:
```css
.react-grid-item {
  will-change: transform;
}
```

## 예방책

- 서드파티 드래그앤드롭/애니메이션 라이브러리에 넘기는 설정 props는 항상
  참조 안정성(useMemo/모듈 상수)을 챙길 것 — 자식 컴포넌트 메모이제이션만으론
  라이브러리 내부 재계산까지는 못 막음
- 리스트 아이템에 무거운 컴포넌트(지도, 차트)가 들어갈 때는 `React.memo` +
  콜백 안정성을 기본값으로 챙길 것(리스트가 커지기 전에 미리)
- 이 개선의 일반화된 패턴은 [[knowledge/patterns/react-grid-drag-memoize-heavy-children]]
  참고

## 관련 페이지

- [[knowledge/patterns/react-grid-drag-memoize-heavy-children]]
- [[projects/dna-sql-agent/decisions/016-dashboard-widget-sizing-model]]
