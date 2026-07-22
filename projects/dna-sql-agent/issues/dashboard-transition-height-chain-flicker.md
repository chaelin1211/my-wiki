---
type: troubleshooting
project: dna-sql-agent
date: 2026-07-03
resolved: true
root-cause: "(1) 전환마다 detail을 즉시 null로 비워 컴포넌트가 매번 언마운트→재마운트됨 (2) 옛 DashboardView 삭제로 h-full을 물려주던 조상이 사라져 DashboardDetail 루트 높이가 auto가 되고 overflow-hidden에 잘림"
related: []
tags: [react, css, flexbox, overflow, remount, scroll]
---

# 대시보드 전환 시 화면 깜빡임 + 스크롤 불가 (원인 2건 연쇄)

## 증상

대시보드 목록에서 다른 대시보드를 클릭하면:
1. 스켈레톤이 잠깐 보였다 사라짐, 위젯이 이상한 크기로 떴다가 다시 재배치됨, 차트가 처음부터
   다시 그려짐 — 전체적으로 정신 사나운 깜빡임
2. (1을 고친 후) 대시보드 화면에서 스크롤이 아예 안 됨
3. (2를 고친 후에도) 전환할 때 화면 전체가 흐려졌다 아니었다 다시 흐려지는 듯한 패턴 지속 리포트

## 환경

- **프레임워크:** Next.js (App Router), Tailwind CSS, react-grid-layout
- **관련 파일:** `components/dashboard-detail.tsx`, `hooks/use-dashboards.ts`, `app/(app)/layout.tsx`
- **재현 조건:** 대시보드가 2개 이상 있는 상태에서 목록 클릭으로 전환

## 시도한 것들

1. ✅ **(원인 1) 즉시 null 비우기 제거** — `loadDetail(id)`가 fetch 시작 직후 `setDetail(null)`을
   호출하던 걸 제거. `db.activeId && db.detail !== null` 조건으로 `DashboardDetail`을 렌더링하던
   `layout.tsx`가, 전환 중 잠깐이라도 `detail`이 `null`이 되면 컴포넌트를 스켈레톤으로 바꿔치기했다가
   새 데이터 도착 시 다시 마운트 — 이 과정에서 react-grid-layout과 그 안의 모든 차트가 처음부터
   다시 렌더링되며 무거운 리마운트가 발생. `null`로 비우지 않고 새 데이터가 도착한 순간에만 교체하도록
   변경 → 컴포넌트가 더 이상 리마운트되지 않음
2. ❌ 스크롤은 여전히 안 됨. `isLoading && 'opacity-50 pointer-events-none'`을 의심해 `pointer-events-none`만
   제거 — 증상 그대로("지금도 없어")
3. ✅ **(원인 2) `h-full` 체인 복원** — 옛 `DashboardView`(삭제됨)가 `<div className="flex h-full overflow-hidden">`로
   `DashboardPanel`+`DashboardDetail`을 함께 감싸며 `h-full`을 내려주고 있었다. 이번 리팩토링으로
   `DashboardDetail`이 사이드바 없이 `layout.tsx` 아래 단독으로 렌더링되면서 이 `h-full`을 잃었다.
   `DashboardDetail`의 루트 `<div className="flex flex-1 min-w-0">`에는 `h-full`이 없어서 —
   `flex-1`은 부모가 flex 컨테이너가 아니면 아무 효과가 없고, `h-full`도 없으니 높이가
   `auto`(콘텐츠만큼)로 계산됨. 부모가 `overflow-hidden`이라 그 콘텐츠가 그냥 **잘렸다**(스크롤이 아니라
   클리핑). `DashboardDetail`/`DashboardDetailSkeleton` 루트에 `h-full`을 명시적으로 추가해서 해결
4. ✅ **(원인 3, 미확정이지만 근본 제거) 로딩 dim 연출 자체를 삭제** — 1·2를 고친 뒤에도 "전체적으로
   뮤트됐다가 아니었다가 다시 뮤트됐다가" 리포트가 계속됨. `isDetailLoading` 기반 `opacity-50` dim이
   왜 여러 번 토글되는지 코드상으로 명확한 원인을 못 찾았음(정적 분석으로는 전환당 1회 pulse만
   예상됨) — 원인 규명 대신, 어차피 (1) 덕분에 전환 중에도 이전 화면이 계속 보이므로 dim 연출
   자체가 불필요하다고 판단해 완전히 제거. `isLoading` prop을 `DashboardDetail`에서 통째로 걷어냄

## 근본 원인

컴포넌트를 삭제/재구성할 때, 그 컴포넌트가 **암묵적으로 물려주던 레이아웃 계약**(이 경우 `h-full`)을
누가 대신 지고 있는지 확인하지 않고 지우면, 자식 쪽은 코드 변경이 전혀 없었는데도 조용히 깨진다.
`DashboardDetail` 자체는 한 줄도 안 바뀌었지만 부모(`DashboardView`)가 사라지며 높이 기반이 사라졌다.

`overflow-hidden` + `height:auto`인 자식 조합은 "스크롤이 안 된다"가 아니라 "잘려서 안 보인다"로
나타나므로, 스크롤 관련 CSS(`overflow-y-auto`, `pointer-events`)를 아무리 만져도 고쳐지지 않는다 —
높이 체인이 끊긴 게 진짜 원인이면 스크롤 컨테이너 자체의 실제 높이가 0에 가깝거나 `auto`라
스크롤할 내용이 "넘치는 상태"로 인식되지 않는다.

## 해결 방법

```tsx
// hooks/use-dashboards.ts — 즉시 null 비우지 않음
const loadDetail = useCallback((id: string) => {
  setIsDetailLoading(true)
  // setDetail(null) 제거 — 새 데이터 도착 전까지 이전 화면 유지
  getDashboard(id)
    .then(d => { if (activeIdRef.current === id) setDetail(d) })
    .catch(() => {})
    .finally(() => { if (activeIdRef.current === id) setIsDetailLoading(false) })
}, [])
```

```tsx
// components/dashboard-detail.tsx — 루트에 h-full 명시
<div className="flex flex-1 min-w-0 h-full">
```

```tsx
// 대시보드 변경 시 리마운트 안 되므로, useState(prop) 초기화만으론 안 갱신되는
// 로컬 상태(localTitle, localStyle)도 dashboard.id 의존 effect에서 같이 동기화 필요
useEffect(() => {
  // ...
  setLocalTitle(dashboard.title)
  setLocalStyle({ ...DEFAULT_STYLE_CONFIG, ...dashboard.styleConfig })
}, [dashboard.id])
```

## 예방책

- 컴포넌트를 삭제하거나 그 트리 구조를 바꿀 때, 삭제 대상이 자식에게 내려주던 레이아웃 클래스
  (`h-full`, `flex`, `min-h-0` 등)를 grep해서 자식 쪽에 재배치했는지 확인할 것
- `overflow-hidden` 컨테이너 안에서 "스크롤이 안 된다" 리포트를 받으면, `overflow-y-auto` 자체보다
  먼저 그 요소까지 이어지는 `height` 체인(각 조상이 정말 definite height를 갖는지)을 devtools
  Computed 탭으로 확인할 것 → [[knowledge/troubleshooting/flex-height-chain-broken-by-missing-h-full]]
- 전환/리스트 아이템 교체 시 "언마운트 후 스켈레톤 후 재마운트"보다는 "이전 콘텐츠 유지 → 새 데이터
  도착 시 교체"가 무거운 하위 트리(그리드 레이아웃, 다건 차트)에서 체감 성능·매끄러움 모두 낫다
- 컴포넌트를 리마운트되지 않게 최적화했다면, 그 컴포넌트 안의 `useState(prop)` 초기화 패턴을 모두
  찾아서 prop 변경 시 동기화하는 effect가 있는지 점검할 것(안 그러면 조용히 stale해짐)

## 관련 페이지

- [[knowledge/troubleshooting/flex-height-chain-broken-by-missing-h-full]]
- 세션: [[projects/dna-sql-agent/sessions/2026-07-03-sidebar-dashboard-header-refactor]]
- ADR: [[projects/dna-sql-agent/decisions/020-context-sensitive-sidebar-swap]] (h-full을 잃게 된 배경 —
  `DashboardView` 삭제)
