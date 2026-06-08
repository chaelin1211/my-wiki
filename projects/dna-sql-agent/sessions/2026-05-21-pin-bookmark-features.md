---
type: session-log
project: dna-sql-agent
date: 2026-05-21
duration: ~4h
focus: "채팅 목록 상단 고정 + 결과 카드 즐겨찾기 기능"
tools-used: [claude-code]
outcome: success
---

# 2026-05-21 — 채팅 목록 상단 고정 + 결과 카드 즐겨찾기

## 목표

- 채팅 목록 상단 고정(pin) 기능 설계 및 구현
- 채팅 결과 카드(chart/dataframe/artifact) 즐겨찾기(bookmark) 기능 설계 및 구현

## 수행한 작업

### Pin 기능
1. `conversations.pinned_at TIMESTAMPTZ NULL` 컬럼 추가 (migration)
2. `PATCH /api/v1/chat/{id}/pin` 엔드포인트 추가 — `{"pinned": bool}` 명시적 상태 전달
3. 목록 정렬 `ORDER BY pinned_at ASC NULLS LAST, updated_at DESC` (새로 고정할수록 아래)
4. `ConversationSummary`에 `pinned_at` 필드 추가
5. `PinRequest`, `PinResponse` 모델 추가
6. 단위 테스트 7건 추가
7. PR #23 생성 및 merge

### Bookmark 기능
1. `bookmarks` 테이블 설계 및 migration 추가
2. `POST /api/v1/bookmarks`, `GET`, `PATCH /{id}/title`, `DELETE /{id}` 구현
3. `component_data`는 스냅샷 저장 안 함 — `messages.components` LATERAL JOIN으로 조회
4. `src/dna/bookmarks/` 모듈 신규 생성
5. `main.py`에 bookmark router mount
6. 단위 테스트 12건 추가
7. component_data 역직렬화 버그 수정 (`_parse_component` 헬퍼)

## 핵심 결정

- **pinned_at vs pinned_sn:** `pinned_sn`은 drag&drop 순서 변경까지 구현해야 해서 over-engineering. `pinned_at`으로 단순화
  → ADR: [[decisions/001-pin-timestamp-vs-sn]]
- **bookmark 스냅샷 vs 참조:** 데이터 중복 피하고 messages 테이블 활용. 대화 삭제 시 북마크도 CASCADE 삭제
  → ADR: [[decisions/002-bookmark-reference-vs-snapshot]]
- **toggle vs 명시적 상태:** `{"pinned": bool}` 명시적 상태 전달 — 연속 클릭 시 의도와 반대 상태 방지
- **conversation_id를 bookmarks에 저장 안 함:** message_id → messages.conversation_id JOIN으로 충분

## 배운 것

- asyncpg LATERAL JOIN에서 `jsonb_array_elements` 결과는 str/dict 모두 올 수 있어 역직렬화 방어 처리 필요
- toggle API보다 명시적 상태 전달이 멱등성과 UX 안정성 모두 높음

## 문제 & 해결

- **문제:** `component_data=dict(row["component_data"])` — asyncpg LATERAL JOIN 결과가 str로 올 때 TypeError
- **원인:** `jsonb_array_elements` 반환값이 드라이버 버전/설정에 따라 str/dict 혼재
- **해결:** `_parse_component(raw)` 헬퍼로 str/dict/None 모두 처리

## 다음 할 일

- [ ] bookmark PR 생성 및 merge
- [ ] 웹 연동 테스트 (message_id는 GET /api/v1/chat/{id} 응답의 messages[].id 사용)
- [ ] 채팅 목록 "No message" 표시 원인 파악
