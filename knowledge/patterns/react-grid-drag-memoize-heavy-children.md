---
type: pattern
tags: [react, performance, drag-and-drop, memoization, css]
related-projects: [dna-sql-agent-web]
---

# 드래그앤드롭 그리드에서 무거운 자식(지도/차트) 버벅임 잡는 3단 체크리스트

## 문제 상황

react-grid-layout류 드래그앤드롭 그리드에서, 리스트 아이템 안에 지도/차트처럼
렌더 비용이 큰 컴포넌트가 있으면 드래그·드롭이 버벅인다. "메모이제이션 하나
추가"로는 안 끝나는 경우가 많다 — React 리렌더 계층과 CSS 컴포지팅 계층을
같이 봐야 한다.

## 체크리스트

### 1. 리스트 아이템을 `React.memo`로 감싼다

드래그 이벤트(`onLayoutChange` 등)가 고빈도로 state를 갱신하면, 부모가
리렌더될 때마다 `.map()`으로 그려지는 모든 자식이 새로 렌더된다. 위치(x/y)만
바뀌는 드래그라면 개별 아이템의 실제 표시 내용(높이, 데이터 등)은 안 바뀌므로
`React.memo`로 스킵 가능해야 한다.

```tsx
export const GridItem = memo(function GridItem({ data, onRemove, ... }) { ... })
```

### 2. `React.memo`로 넘어가는 콜백/객체 props를 전부 안정화한다

`memo`는 얕은 비교라, 콜백이 렌더마다 새로 생성되면(`() => {...}`를 인라인으로
넘기거나 `useCallback` 없이 선언) 무력화된다. 부모의 이벤트 핸들러는 `useCallback`,
설정 객체는 `useMemo` 또는 컴포넌트 밖 모듈 상수로 뺀다.

```tsx
const handleRemove = useCallback((id) => { ... }, [])       // deps 최소화
const gridConfig = useMemo(() => ({ rowHeight, cols }), [rowHeight, cols])
const STATIC_CONFIG = { enabled: false }  // 아예 안 바뀌면 모듈 스코프로
```

### 3. 서드파티 라이브러리에 넘기는 props도 참조 안정성을 챙긴다

자식 렌더링 최적화만으로는 라이브러리 **내부** 재계산까지 막지 못한다.
`gridConfig={{ ... }}`처럼 매 렌더 새 리터럴을 넘기면, 값이 안 바뀌어도
라이브러리가 "prop이 바뀌었다"고 판단해 내부 상태를 다시 계산할 수 있다.
(2)와 동일한 방식으로 안정화한다.

### 4. 드롭/애니메이션 종료 시점의 CSS를 확인한다

라이브러리가 기본으로 "드래그 중"에는 `transition: none` + `will-change`를
걸어주지만, **드롭 후 재배치되는 다른 아이템들**에는 안 걸려 있는 경우가 흔하다
(예: `.react-grid-item.react-draggable-dragging { will-change: transform }`처럼
드래그 중인 아이템에만 스코프됨). 이러면 드롭 순간 여러 아이템이 GPU 레이어
승격 없이 `transform` 전환을 실행해서, 무거운 내용이 매 프레임 다시 그려진다.

```css
/* 재배치되는 모든 아이템에 상시 적용 */
.react-grid-item {
  will-change: transform;
}
```

`will-change`는 브라우저에게 "이 요소는 곧 transform이 바뀔 거다"라고 미리
알려서 GPU 레이어로 승격시키는 힌트일 뿐, 코드로 직접 승격을 트리거하는 게
아니다. 승격되면 이후 transform 변경은 CPU 리페인트 없이 GPU 합성만으로 처리된다.

## 왜 순서대로 봐야 하나

1~2만 고치면 드래그 자체는 부드러워지지만 드롭 순간은 여전히 버벅일 수 있다
(원인이 CSS 컴포지팅 계층에 있으므로). 반대로 4만 고치면 드래그 중 리렌더
비용은 그대로 남는다. 증상이 "드래그 중 계속 끊김"인지 "드롭 순간만 멈칫"인지로
어느 계층이 문제인지 가늠할 수 있다.

## 실제 적용 사례

- [[projects/dna-sql-agent/issues/dashboard-drag-drop-jank-heavy-widgets]]
