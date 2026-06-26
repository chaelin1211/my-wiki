---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-26
resolved: true
root-cause: "setState 업데이터 함수 내부에서 부수효과(router.push) 호출"
related: []
tags: [react, dashboard, frontend]
---

# 대시보드 삭제 시 setState-in-render 오류 + 전체 새로고침 일부만 됨

## 증상

```
Cannot update a component (`Router`) while rendering a different component (`DashboardView`).
```
- 현재 대시보드 삭제 시 위 경고. Strict Mode에서 중복 동작(네비게이션 2회 등) 관찰.
- 별개로, 전체 새로고침 시 일부 위젯만 갱신됨.

## 환경

- **런타임:** React 18 (Strict Mode, dev)
- **재현 조건:** 활성 대시보드 삭제 / 전체 새로고침 버튼

## 근본 원인

1. **삭제**: `handleDeleted`가 `setDashboards(prev => { ... setActiveId(); router.push(); ... })` 처럼 **상태 업데이터 함수 내부에서 부수효과**(router.push)를 호출. 업데이터는 렌더/커밋 단계에서 실행되므로 렌더 중 Router 갱신 → 경고. Strict Mode가 impure 업데이터를 2회 실행해 중복 동작.
2. **전체 새로고침**: `handleRefreshAll`이 위젯마다 `onUpdated({...dashboard, ...})`를 호출하는데 각 호출이 **stale `dashboard`** 클로저 기준 → 동시 실행 시 마지막 결과만 남고 나머지 원복.

## 해결 방법

1. 부수효과를 업데이터 밖으로:
```ts
const next = dashboards.filter(x => x.id !== id)
setDashboards(next)
if (activeId === id) { /* setActiveId + router.push */ }
```
2. 새로고침 결과를 모아 한 번에 반영:
```ts
const updates = new Map() // widgetId -> chartData
// Promise.allSettled로 모은 뒤
onUpdated({ ...dashboard, widgets: dashboard.widgets.map(w => updates.has(w.id) ? {...w, cachedChartData: updates.get(w.id)} : w) })
```

## 교훈

- **setState 업데이터 함수는 순수해야 한다** — router.push/다른 setState 등 부수효과 금지(Strict Mode 2회 실행로 표면화).
- 동시 비동기 업데이트는 개별 `onUpdated(stale)` 대신 결과를 모아 한 번에 반영해 last-write-wins clobber 방지.
