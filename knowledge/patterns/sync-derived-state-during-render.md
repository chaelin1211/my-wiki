---
type: knowledge
category: pattern
date: 2026-10-08
tags: [react, state, effects, race-condition]
---

# prop에서 파생한 편집 가능한 state는 effect가 아니라 렌더 중에 맞춘다

## 문제 패턴

prop(예: 전체 검색에서 넘어온 검색어)을 초깃값으로 쓰되 사용자가 고칠 수 있는 state(입력칸 값)로 만들고, prop이 바뀌면 `useEffect(() => setState(prop), [prop])`로 동기화한다. 그러면 prop이 바뀐 렌더에서는 state가 아직 이전 값이다. 같은 렌더의 다른 effect가 그 state로 계산하고 "한 번만 실행" 가드(ref에 키 기록 등)를 걸면, 이전 값으로 계산된 결과가 확정되고 다시 계산되지 않는다.

사례: 대화를 보던 중 다른 검색 결과를 누르면, "처음 이동할 일치" 계산이 이전 검색어의 일치 목록으로 실행되어 엉뚱한 위치·순번이 잡힘.

## 해결 패턴

React 공식 문서의 "렌더 중에 state 조정" 패턴을 쓴다. prop 출처를 state로 기억해 두고, 렌더 중에 달라졌으면 바로 `setState`한다. React는 자식 렌더·effect 실행 전에 이 컴포넌트를 즉시 다시 렌더하므로, effect들은 처음부터 새 값을 본다.

```tsx
const sourceKey = `${targetKey ?? ''}\u0000${query ?? ''}`
const [source, setSource] = useState(sourceKey)
const [input, setInput] = useState(query ?? '')
if (source !== sourceKey) {
  setSource(sourceKey)
  setInput(query ?? '')
}
```

- 같은 컴포넌트의 state만 이렇게 바꾼다(다른 컴포넌트 state 변경 금지).
- ref 초기화 같은 부수 효과는 별도 effect로 두되, 그 effect가 값을 읽는 effect보다 먼저 선언되게 한다(effect는 선언 순서대로 실행).
- 가능하면 애초에 파생 state를 두지 않고 렌더 중 계산(`useMemo`)이나 `key` 리셋으로 해결하는 쪽을 먼저 검토한다. 사용자 편집이 필요할 때만 이 패턴.

## 실제 사례

- dna-sql-agent-web 대화 내 검색 바 검색어(`components/chat-view.tsx`), 웹 PR #100 → [[projects/dna-sql-agent/sessions/2026-10-08-conversation-search-review-and-in-chat-find]]
