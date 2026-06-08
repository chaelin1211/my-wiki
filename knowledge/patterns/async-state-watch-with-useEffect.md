---
type: pattern
tags: [react, state, useEffect, timing]
---

# 비동기 state 업데이트 감지 — pendingKey + useEffect 패턴

## 문제

`onSave` 콜백 안에서 방금 업데이트된 state를 즉시 읽으면 이전 값이 나온다.

```tsx
// ❌ 이렇게 하면 newGroup을 못 찾을 수 있다
const handleSave = async () => {
  await createGroup(name)   // 내부에서 setGroups(...) 호출
  const newGroup = groups.find(g => g.name === name)  // 아직 이전 groups
  if (newGroup) openDialog(newGroup)
}
```

React state 업데이트는 비동기이므로, `setGroups`를 호출한 직후에도 현재 렌더 사이클의 `groups` 클로저는 이전 값을 가리킨다.

## 해결

"나중에 이 값이 나타나면 실행해" 패턴 — pending key를 state에 보관하고 `useEffect`로 감지한다.

```tsx
const [pendingName, setPendingName] = useState<string | null>(null)

useEffect(() => {
  if (!pendingName) return
  const found = groups.find(g => g.name === pendingName)
  if (found) {
    openDialog(found)
    setPendingName(null)
  }
}, [groups, pendingName])

const handleSave = async (name: string) => {
  await createGroup(name)   // 내부에서 load() → setGroups(newList)
  setPendingName(name)      // 다음 렌더에서 useEffect가 감지
}
```

## 적용 조건

- 어떤 액션 완료 후 비동기로 업데이트되는 배열에서 항목을 찾아야 할 때
- `await` 이후 바로 state를 읽어야 하는 상황

## 실제 사용 예

- `dna-sql-agent-web`: 그룹 생성 완료 → `groups` 배열에 새 그룹이 들어오면 멤버 관리 다이얼로그 자동 오픈
