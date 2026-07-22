---
type: troubleshooting
project: dna-sql-agent
date: 2026-07-09
resolved: true
root-cause: "DB는 ON DELETE CASCADE로 정상 삭제되지만, 프론트 대시보드 상태는 activeId가 안 바뀌면 재조회를 안 해서 옛 위젯 목록을 계속 보여줌"
related: [projects/dna-sql-agent-web]
tags: [react, state-sync, dashboard, bookmark]
---

# 북마크 삭제해도 이미 열어둔 대시보드에서 위젯이 안 사라짐

> 새 이슈 파일명: `dashboard-widget-stale-after-bookmark-deleted.md`

## 증상

채팅에서 북마크를 해제하거나 북마크 뷰에서 카드를 제거해도, 그 전에 이미 열어서
보고 있던 대시보드 화면에서는 해당 위젯이 그대로 남아있음(새로고침하면 사라짐).

## 환경

- **OS:** -
- **런타임:** Next.js(프론트), FastAPI + Postgres(백엔드)
- **관련 패키지:** -
- **재현 조건:** 대시보드를 한 번 연 상태에서, 같은 세션 내 채팅/북마크 뷰로
  이동해 그 대시보드에 포함된 북마크를 삭제

## 시도한 것들

1. ❌ DB 스키마 확인 — `dashboard_widgets.bookmark_id REFERENCES bookmarks(id)
   ON DELETE CASCADE`가 이미 걸려 있어 DB 레벨에서는 문제없음(북마크 삭제 시
   위젯 row도 같이 삭제됨) → DB 문제가 아님
2. ✅ 프론트 `app/(app)/layout.tsx`의 대시보드 상세 로드 조건 확인:
   ```ts
   if (urlId && urlId !== db.activeId && db.dashboards.some(...)) {
     db.loadDetail(urlId)
   }
   ```
   같은 대시보드로 "돌아왔을 때"는 `urlId === db.activeId`라 재조회가 안 됨

## 근본 원인

`bm`(북마크)과 `db`(대시보드) 훅이 서로 독립적으로 상태를 들고 있어서, 한쪽에서
일어난 변경(북마크 삭제)이 다른 쪽(이미 로드된 대시보드 상세)에 전파되지 않음.
대시보드 상세는 "다른 대시보드로 전환할 때만" 재조회하도록 되어 있어서, 같은
대시보드를 보고 있는 동안 발생한 외부 변경을 반영할 방법이 없었음.

## 해결 방법

`hooks/use-bookmarks.ts`의 `useBookmarks`에 선택적 콜백을 추가:

```ts
export function useBookmarks(email: string | null, onBookmarkRemoved?: () => void) {
  ...
  await deleteBookmark(id)
  onBookmarkRemoved?.()   // toggleBookmark/removeBookmark/softRemoveBookmark 모두
}
```

`lib/app-context.tsx`(두 훅을 조합하는 지점)에서 연결:

```ts
const handleBookmarkRemoved = useCallback(() => {
  if (dbActiveIdRef.current) dbLoadDetailRef.current(dbActiveIdRef.current)
}, [])
const bm = useBookmarks(email ?? null, handleBookmarkRemoved)
```

## 예방책

- 서로 독립된 훅(bm, db 등)이 실제로는 서로 연관된 데이터를 다룰 때, "한쪽의
  성공적인 mutation이 다른 쪽 캐시를 무효화해야 하는지"를 항상 점검할 것
  (이 프로젝트는 아직 react-query 같은 캐시 무효화 라이브러리를 안 쓰고
  훅을 직접 조합하는 구조라, 이런 교차 무효화를 수동으로 챙겨야 함)
- 비슷한 유형의 과거 이슈: [[projects/dna-sql-agent/issues/dashboard-account-switch-stale-state]]
  (로그아웃/재로그인 시 잔존 상태), [[projects/dna-sql-agent/issues/logout-stale-conversation-list]]

## 관련 페이지

- [[projects/dna-sql-agent/decisions/015-bookmark-dashboard-architecture]]
