---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-30
resolved: true
root-cause: "채팅 진입 시 북마크 매핑 맵을 로드하지 않음 + 로드해도 페이지네이션(20개)으로 일부만 채워짐"
related: []
tags: [bookmark, frontend, pagination]
---

# 채팅 북마크 표시 아이콘 누락 (가끔/전부)

## 증상

채팅 내 북마크된 시각화 카드의 북마크 토글 아이콘(활성 표시)이 **가끔 또는 전부** 누락. `/bookmarks` 페이지를 다녀오면 일부 정상화.

## 환경

- **런타임:** Next.js (dna-sql-agent-web)
- **관련:** `hooks/use-bookmarks.ts`(`componentIdMapRef`), `app/(app)/layout.tsx`, 백엔드 `src/dna/bookmarks/routes.py`
- **재현 조건:** 새로고침 후 채팅 직행, 또는 북마크 20개 초과

## 근본 원인

카드의 북마크 여부는 `getBookmarkId(componentId)` = `componentIdMapRef` 조회로만 판단한다.

1. 대화 전환 effect가 **피드백만 로드**하고 북마크는 안 불러옴 → 맵이 비어 전부 미표시
2. `loadBookmarks()`도 `PAGE_SIZE=20`만 로드 → 21번째 이후 북마크 카드는 맵에 없어 미표시(개수·정렬에 따라 "가끔" 누락)

## 해결 방법

대화별 **경량 refs 전체 조회** 엔드포인트를 추가하고 채팅 진입 시 호출:

- 백엔드: `GET /api/v1/bookmarks/refs?conversation_id=` — `component_id↔id` 쌍만, 페이지네이션 없음(무거운 jsonb/JOIN 없이 최소 컬럼)
- 프론트: 대화 전환 effect에서 `loadBookmarkRefs(conversationId)`로 매핑 맵을 전부 채움. 맵은 ref라 리렌더가 안 되므로 버전 state로 강제 리렌더. `refreshMap`은 전체 교체→병합으로 바꿔 채팅 refs와 북마크 페이지 로드가 같은 맵 공유.

## 예방책

- "특정 id가 북마크인지"를 맵 조회로 판단할 땐, 그 맵이 **해당 화면 진입 시 빠짐없이 채워지는지** 확인(페이지네이션·로드 시점).

## 관련 페이지

- [[decisions/015-bookmark-dashboard-architecture]]
