---
type: issue
project: dna-sql-agent-web
date: 2026-05-26
resolved: true
---

# 북마크 soft remove 후 재북마크 시 순서 변경 및 다중 항목 사라짐

## 증상

1. 북마크를 삭제(soft remove)한 뒤 같은 항목을 다시 북마크하면 카드가 목록 맨 위로 이동
2. 여러 항목을 soft remove한 상태에서 하나만 재북마크하면 나머지 soft remove 항목이 화면에서 사라짐

## 원인

**증상 1 — 순서 변경:**
- `softRemoveBookmark`는 `componentIdMapRef`에서 해당 항목 제거 (API 삭제만, `bookmarks` 배열 유지)
- 재북마크 시 `toggleBookmark`의 "add" 경로 실행 → 새 임시 항목을 배열 **맨 앞에 prepend**
- `bookmarks`에 old + new 두 항목이 생기고, dedup 로직이 new 기준(맨 앞 위치)으로 처리

**증상 2 — 다른 항목 사라짐:**
- `rebookmark`가 `setBookmarks`를 호출하면 `bookmarks` 상태 변경 → useMemo 재실행
- useMemo 내부의 `bookmarks.filter((b) => !pendingRemovedRef.current.has(b.id))` 실행
- `pendingRemovedRef`에 다른 soft remove id들이 남아있어 해당 항목들이 필터에 걸려 제거됨
- 평소엔 soft remove 시 `bookmarks`가 변경되지 않아 useMemo가 재실행되지 않아 잠복해 있던 버그

## 해결

1. `rebookmark` 함수 신설: 기존 `bookmarks[idx]`의 id를 API 응답 id로 교체 (in-place)
   → prepend 없음, 위치 유지
2. useMemo에서 `bookmarks.filter` 제거
   → soft remove 항목의 표시 여부는 `isBookmarked: (b) => !pendingRemovedIds.has(b.id)`로만 처리

## 관련 파일

- `hooks/use-bookmarks.ts` — `rebookmark` 함수 추가
- `components/bookmark-view.tsx` — useMemo filter 제거, `onRebookmark` props에 `id` 추가
- `app/page.tsx` — `onRebookmark={bm.toggleBookmark}` → `bm.rebookmark`
