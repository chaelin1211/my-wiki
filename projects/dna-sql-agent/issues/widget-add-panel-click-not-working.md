---
type: issue
project: dna-sql-agent
date: 2026-06-15
resolved: true
tags: [frontend, css, react-grid-layout, pointer-events]
---

# widget-add-panel 클릭 인터랙션 불동

## 증상

위젯 추가 패널에서 북마크 목록이 보이지만 클릭이 전혀 안 됨.
닫기(X) 버튼도 동작하지 않음.

## 원인 분석

복합 원인:

1. **아이템 div에 onClick 없음**: 북마크 아이템 행 전체가 클릭 가능해 보이지만(`cursor-pointer`), 실제 onClick은 `h-7 w-7` 크기의 `+` 버튼에만 있었음 — 사용자는 행 전체를 누르려 하나 실제 클릭 영역은 매우 작음

2. **overflow-hidden 부모가 포인터 이벤트 영역 축소 가능**: `DashboardDetail`의 외부 컨테이너가 `flex flex-1 min-w-0 overflow-hidden`이었는데, 이 overflow-hidden이 시각적으로 보이는 패널의 히트 영역을 실제로 줄이지는 않지만, 레이아웃 계산 실수 시 패널이 visible 영역 밖으로 렌더되어 클릭 안 되는 증상 가능

3. **ScrollArea의 포인터 이벤트 이슈**: shadcn ScrollArea(Radix 기반)가 특정 flex 컨텍스트에서 포인터 이벤트를 차단하는 케이스 존재

## 해결

`widget-add-panel.tsx`:
- 아이템 div 전체에 `onClick`, `onKeyDown` 추가 (`role="button"`)
- `ScrollArea` → 네이티브 `overflow-y-auto` div로 교체
- 패널 루트에 `z-10 relative` 추가 (react-grid-layout 오버레이보다 위)
- `Button` 컴포넌트 제거 → 아이콘만 표시 (클릭 대상이 명확해짐)

`dashboard-detail.tsx`:
- 외부 컨테이너 `overflow-hidden` 제거 → `flex flex-1 min-w-0`

## 교훈

- shadcn `ScrollArea`는 복잡한 flex 레이아웃에서 포인터 이벤트 문제를 유발할 수 있음 → 단순한 스크롤은 `overflow-y-auto` div가 더 안전
- react-grid-layout은 드래그 중 전역 이벤트를 캡처하므로, 같은 flex 컨테이너 안에 인터랙티브 UI를 넣을 때 `z-index` 명시 필요
- 클릭 가능해 보이는 영역과 실제 이벤트 핸들러 영역이 다를 경우 UX 버그로 직결 — `cursor-pointer`가 있으면 반드시 `onClick`도 있어야 함
