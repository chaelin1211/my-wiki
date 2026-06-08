---
type: session-log
project: dna-sql-agent
date: 2026-05-26
duration: ~1h
focus: "채팅 목록 API last_message 필드 추가"
tools-used: [claude-code]
outcome: success
---

# 2026-05-26 — 채팅 목록 API last_message 필드 추가

## 목표

채팅 목록(`GET /api/v1/chat`) 응답에 각 대화의 마지막 assistant 메시지를 포함하여 프론트엔드가 미리보기를 표시할 수 있도록 한다.

## 수행한 작업

1. `ConversationSummary` Pydantic 모델에 `last_message: Optional[str] = None` 필드 추가 (`src/dna/chat/models.py`)
2. `list_conversations` SQL 쿼리에 LATERAL 서브쿼리 추가 — `role = 'assistant'` 메시지 중 `created_at DESC LIMIT 1` 조회
3. `ConversationSummary` 생성 시 `last_message=row["last_message"]` 매핑 추가
4. PR #28 생성 (`feat/chat-list-description` → `main`)

## 핵심 결정

- **LATERAL JOIN 방식 선택:** 목록 조회 1회로 last_message까지 가져오는 방식. 별도 쿼리(N+1)나 애플리케이션 레벨 조합 대신 DB에서 한 번에 처리.
  → 패턴: [[knowledge/patterns/postgres-lateral-latest-row-per-group]]

## 배운 것

- PostgreSQL LATERAL JOIN + `ORDER BY … LIMIT 1` 패턴은 그룹별 최신 1건 조회의 표준 방법
- `COUNT(*) OVER()` 윈도우 함수는 LATERAL JOIN 추가 후에도 `conversations c` 기준으로 카운트되어 total에 영향 없음

## 문제 & 해결

없음 (단순 구현)

## 다음 할 일

- [ ] PR #28 리뷰 및 merge
- [ ] 프론트엔드에서 `last_message` 필드 활용하여 대화 목록 미리보기 표시