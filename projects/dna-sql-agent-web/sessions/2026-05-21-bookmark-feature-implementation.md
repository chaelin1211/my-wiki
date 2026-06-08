---
type: session-log
project: dna-sql-agent-web
date: 2026-05-21
duration: ~4h
focus: "대화 고정(pin) PR 머지 + 북마크 기능 구현"
tools-used: [claude-code]
outcome: success
---

# 2026-05-21 — 대화 고정(pin) 머지 + 북마크 기능 구현

## 목표

1. 대화 고정(pin) 기능 PR 머지 — PR #10
2. 채팅 응답의 차트·표·아티팩트 컴포넌트에 북마크 기능 추가.
   - 컴포넌트 헤더에 북마크 토글 아이콘
   - 사이드바에 북마크 메뉴 버튼
   - 북마크 조회 화면 (검색, 정렬, 카드 그리드, 인라인 제목 편집)

## 수행한 작업

### 대화 고정(pin)
1. `pinConversation` API 함수 추가 (`lib/chat-api.ts`)
2. `handlePinConversation` 구현 (`hooks/use-conversations.ts`) — 낙관적 업데이트 + 서버 동기화
3. `sortConversations` 유틸 (`lib/utils.ts`) — 고정된 대화를 상단 정렬
4. 대화 목록 UI에 핀 토글 버튼 추가 (`components/conversation-list.tsx`)
5. PR #10 "feat: 대화 핀 기능 추가" 머지 완료 (2026-05-21 05:50)

### 북마크
1. `lib/types.ts` — `Bookmark` 인터페이스, `Message.backendMessageId` 추가
2. `lib/chat-api.ts` — `mapBookmark()`, `getBookmarks`, `addBookmark`, `updateBookmarkTitle`, `deleteBookmark` 추가
3. `hooks/use-bookmarks.ts` 신규 — 낙관적 업데이트, componentIdMap O(1) 조회
4. `hooks/use-conversations.ts` — `patchBackendMessageIds` 추가 (SSE 완료 후 backendMessageId만 패치)
5. `hooks/use-chat-stream.ts` — `onDone` 에서 `loadConversationMessages` → `patchBackendMessageIds` 교체
6. `components/chat-message.tsx` — 각 step에 북마크 토글 버튼 연결
7. `components/chart-block.tsx` — `isBookmarked`, `onBookmark`, `flat` prop 추가
8. `components/devextreme-chart-block.tsx` — 동일
9. `components/data-table.tsx` — 동일 + flat 시 헤더·접힘 없이 테이블만 렌더
10. `components/conversation-list.tsx` — 북마크 사이드바 버튼 추가
11. `components/bookmark-view.tsx` 신규 — BookmarkCard, BookmarkPreview, 검색/정렬
12. `app/page.tsx` — `viewMode`, `useBookmarks` 연결, BookmarkView 조건부 렌더

## 핵심 결정

- **patchBackendMessageIds 분리:** SSE 완료 후 `loadConversationMessages` 호출 시 API 재빌드로 차트 steps가 날아가는 문제 → backendMessageId만 패치하는 경량 함수 분리
  → ADR 작성 불필요 (구현 내 명확한 선택)

- **flat prop 패턴:** `BookmarkPreview`에서 내부 컴포넌트의 카드 chrome(border, header, 접힘)을 제거할 때 `[&>div]` CSS 핵 대신 `flat` prop으로 처리
  → 컴포넌트 자체가 렌더 분기 책임을 가짐

- **북마크 아이콘:** 북마크 상태 표시를 `BookmarkCheck`(checkmark) → filled `Bookmark`(`fill-primary`)로 통일

## 배운 것

- `backendMessageId` 수집: SSE에서는 메시지 ID 미제공 → SSE 완료 후 별도 API 호출로 패치. 이때 백엔드 응답에 `tool` role 메시지가 포함되므로 필터링 필수 (index 불일치 방지)
- Turbopack 정적 분석: 인터페이스만 있는 `.ts` 파일은 런타임 export 없음 → `import type` 강제
- 백엔드 `component_data` 구조: `{ id, type, data: <실제 payload>, ... }` — payload는 한 단계 더 안에 있음

## 문제 & 해결

- **문제:** 차트 step이 SSE 완료 후 사라짐
  - **원인:** `onDone`에서 `loadConversationMessages` 호출 → API 응답으로 steps 재빌드 → SSE로 쌓인 steps 덮어씀
  - **해결:** `patchBackendMessageIds` 분리 — steps 재빌드 없이 ID만 패치
  → 이슈: [[issues/sse-steps-overwritten-by-reload]]

- **문제:** BookmarkPreview에서 표/차트 미렌더
  - **원인:** `component_data.data.data`가 실제 rows인데 `data.rows`로 접근
  - **해결:** `payload = componentData.data`, `rows = payload.data`로 경로 수정
  → 이슈: [[issues/bookmark-component-data-mapping]]

- **문제:** 북마크 앱 시작 시 `TypeError: Failed to fetch` 콘솔 에러
  - **원인:** 마운트 시 `loadBookmarks` 호출 → 미구현 엔드포인트 → CORS preflight 404 → 브라우저 차단
  - **해결:** `viewMode === 'bookmarks'` 진입 시점에만 lazy load


