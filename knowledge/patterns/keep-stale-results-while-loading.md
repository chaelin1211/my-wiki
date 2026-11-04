---
type: knowledge
category: pattern
date: 2026-10-08
tags: [react, search, ux, loading-state]
---

# 검색 중에도 이전 결과를 유지해 목록 깜빡임 없애기

## 문제 패턴

입력할 때마다(디바운스 후) 검색 요청을 보내면서 `isLoading ? <스피너/> : <목록/>`으로 렌더링하면, 응답이 빨라도 매번 목록이 사라졌다가 다시 나타나 화면이 깜빡인다. 첫 검색 직전(디바운스 대기 중)에는 결과가 비어 있어 "결과 없음"이 잠깐 번쩍이기도 한다.

## 해결 패턴

- **결과와 "그 결과를 만든 검색어"를 함께 저장한다.** 새 응답이 올 때까지 이전 결과를 그대로 보여 주고, 로딩은 제목 옆 작은 스피너 정도로만 표시한다.
- **로딩 화면은 지연 표시한다.** `isLoading`이 300ms 이상 이어질 때만 전체 로딩 상태로 바꾼다. 빠른 응답에서는 스피너가 아예 보이지 않는다.
- **"아직 검색한 적 없음"과 "결과 0건"을 구분한다.** 결과 검색어가 `null`이면 같은 높이의 빈 영역, 값이 있는데 0건이면 "결과 없음".
- **하이라이트·선택은 화면 결과의 검색어로 한다.** 입력 중인 값으로 칠하면 목록보다 강조가 먼저 바뀌어 어긋나 보인다.
- 오래된 응답이 새 결과를 덮지 않도록 요청 번호 확인은 그대로 둔다 → [[knowledge/patterns/request-token-stale-response-guard]].

```tsx
const [resultsQuery, setResultsQuery] = useState<string | null>(null)
const [isSlowLoading, setIsSlowLoading] = useState(false)

useEffect(() => {
  if (!isLoading) { setIsSlowLoading(false); return }
  const timer = setTimeout(() => setIsSlowLoading(true), 300)
  return () => clearTimeout(timer)
}, [isLoading])

// 렌더링
results.length > 0 ? <List heading={<>{total}개 결과 {isLoading && <Spinner />}</>} />
  : isSlowLoading ? <Loading />
  : resultsQuery == null ? <div className="min-h-48" />
  : <Empty />
```

## 실제 사례

- dna-sql-agent-web 대화 검색창(`components/search-dialog.tsx`), 웹 PR #100 → [[projects/dna-sql-agent/sessions/2026-10-08-conversation-search-review-and-in-chat-find]]
