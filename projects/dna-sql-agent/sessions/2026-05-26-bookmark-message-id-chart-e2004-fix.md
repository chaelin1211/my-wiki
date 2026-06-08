---
type: session-log
project: dna-sql-agent
date: 2026-05-26
duration: ~3h
focus: "북마크 신규 메시지 404 수정, SSE done 이벤트 개편, 차트 E2004 수정"
tools-used: [claude-code]
outcome: success
---

# 2026-05-26 — 북마크 message_id 전달 & 차트 E2004 수정

## 목표

- 프론트엔드가 SSE 응답 완료 후 북마크 생성 시 message_id를 알 수 없어 404가 발생하는 문제 해결
- DevExtreme 차트 렌더링 시 LLM이 잘못된 컬럼명을 넘겨 E2004 오류가 발생하는 문제 해결

## 수행한 작업

1. `BookmarkResponse`에 `component_created_at` 필드 추가 (컴포넌트/메시지 생성 시각)
2. `sort_by=created_at` 정렬 기준을 북마크 생성일(`b.created_at`) → 컴포넌트 생성일(`m.created_at`)로 변경
3. SSE 스트림 종료 이벤트를 `data: [DONE]` → `data: {"type": "done", "message_id": ..., "conversation_id": ...}` JSON으로 교체
   - `SaveComponentsMiddleware._save_components()` 반환값을 `int | None`으로 변경
   - `[DONE]` 대신 message_id가 포함된 done 이벤트 emit
4. DevExtreme 차트 컬럼명 검증 로직 추가
   - `DnaVisualizeDataTool._resolve_col()`: 대소문자 무시 매칭 → 없으면 None 반환 (auto-select fallback)
   - `DnaVisualizeDataArgs` x_col/y_col/color_col/y_cols description에 "exact column name" 명시
5. `docs/sse-analysis.md`, `docs/bookmark-design.md` 문서 업데이트
6. PR #27 생성 (`fix/chat-bookmark` → `main`)

## 핵심 결정

- **SSE [DONE] → JSON done 이벤트:** message_id는 ChatSaveHook(DB INSERT)이 완료된 후에야 생성되므로 기존 SSE 청크에는 포함 불가. `SaveComponentsMiddleware`가 `[DONE]` 감지 후 `_save_components()`에서 얻은 id를 done 이벤트에 실어 보내는 방식 채택.
  → ADR: [[decisions/003-sse-done-event-message-id]]

## 배운 것

- `ChatSaveHook`(메시지 INSERT) → `[DONE]` emit → `SaveComponentsMiddleware`(`_save_components`) 순서로 실행되므로, 미들웨어 시점에는 이미 message row가 존재함
- 북마크 가능 컴포넌트(chart/artifact)가 있으면 `component_buffer`는 항상 non-empty → `_save_components()` 항상 실행 → message_id 항상 획득 가능
- Starlette `BaseHTTPMiddleware`에서 SSE chunk를 직접 yield할 때는 반드시 `bytes`로 인코딩 필요 (`str` yield 시 `TypeError: sequence item N: expected a bytes-like object, str found`)

## 문제 & 해결

- **문제:** SSE done 이벤트에서 str yield → `TypeError: expected a bytes-like object`
- **원인:** `BaseHTTPMiddleware`의 `body_iterator`는 bytes를 기대하는데 str을 yield
- **해결:** `f"data: {...}\n\n".encode("utf-8")`로 인코딩
  → 이슈: [[issues/sse-middleware-str-bytes-type-error]]

- **문제:** DevExtreme 차트 E2004 — LLM이 `table_schema` 넘겼으나 실제 컬럼은 `schema_name`
- **원인:** `DxChartGenerator._build_series()`에서 x_col/y_col을 검증 없이 `argumentField`/`valueField`에 직접 사용
- **해결:** `_resolve_col()` 메서드로 대소문자 무시 매칭 후 없으면 None(auto-select fallback)

## 다음 할 일

- [ ] 프론트엔드에서 `type: "done"` 이벤트 수신 및 `message_id` 활용하여 북마크 생성 연동
- [ ] PR #27 리뷰 및 merge
