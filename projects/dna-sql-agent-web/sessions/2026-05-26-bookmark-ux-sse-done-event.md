---
type: session-log
project: dna-sql-agent-web
date: 2026-05-26
duration: ~3h
focus: "북마크 UX 개선 + SSE done 이벤트 message_id 수신 처리"
tools-used: [claude-code]
outcome: success
---

# 2026-05-26 — 북마크 UX 개선 & SSE done 이벤트 처리

## 목표

- 북마크 카드 차트 높이 초과 버그 수정
- 채팅에서 바로 북마크 시 not found 이슈 원인 파악 및 해결
- SSE 스트림 종료 이벤트 명세 변경 대응

## 수행한 작업

1. **북마크 카드 차트 높이 초과 수정** — `flat` 모드 `p-2` padding을 제거하고 `BookmarkCard` 컨텐츠 영역에 `p-2` + chartHeight 보정(−16px)으로 이전
2. **북마크 생성일 기준 변경** — `mapBookmark`에서 `created_at` → `component_created_at` 우선 사용
3. **SSE done 이벤트 처리** — `type:done` JSON 이벤트 파싱 추가, `message_id` / `conversation_id` 직접 수신해 `backendMessageId` 즉시 세팅. `[DONE]` 문자열은 폴백 유지
4. **북마크 대기 스피너** — `backendMessageId == null` 동안 차트·아티팩트 헤더에 `Loader2` 스피너 표시, 세팅 완료 시 북마크 아이콘으로 자동 전환
5. **DevExtreme 파이 차트 E2101 수정** — `config.kind === 'pie'` 외에 `series[0].type === 'pie'`도 확인하도록 보정
6. **문서 갱신** — `sse-analysis.md`, `bookmark-design.md`, `devextreme-chart-design.md` 업데이트
7. **PR #14 생성**

## 핵심 결정

- **SSE done 이벤트 신규 포맷 프론트 선반영**: 백엔드 적용 전이지만 `[DONE]` 폴백 유지하며 신포맷 파싱 먼저 구현
  → ADR: [[decisions/004-sse-done-event-message-id]]

- **북마크 스피너 조건**: `!isStreaming` 체크 없이 `backendMessageId == null`만으로 판단. 신 백엔드에서는 `isStreaming: false`와 `backendMessageId` 세팅이 동일 렌더 사이클에 일어나므로 `!isStreaming` 조건 시 스피너가 노출되지 않음

## 배운 것

- React 18 자동 배칭: 동일 Promise 콜백 내 여러 `setState`는 단일 렌더로 처리됨 → 두 상태를 동시에 바꾸면 중간 상태가 렌더링되지 않음
- DevExtreme `Chart` vs `PieChart`: 파이 차트는 별도 `PieChart` 컴포넌트 필요, `type="pie"`를 일반 `Chart`에 전달하면 E2101

## 문제 & 해결

- **문제:** 채팅에서 바로 북마크 시 not found (404)
- **원인:** SSE 완료 후 `patchBackendMessageIds`(별도 API 재호출)가 비동기로 실행되는 동안 `backendMessageId`가 없어 북마크 불가. 또한 신 백엔드에서 `message_id`를 `done` 이벤트에 실어 보내지 않아 타이밍 레이스 발생
- **해결:** SSE `done` 이벤트에서 `message_id` 직접 수신해 즉시 세팅, `patchBackendMessageIds`는 null 폴백으로만 유지
  → 이슈: [[issues/bookmark-not-found-on-chat]]

- **문제:** DevExtreme E2101 — Unknown series type: pie
- **원인:** `config.kind`가 `'pie'`가 아닌데 `series[0].type`이 `'pie'`인 경우 일반 `Chart`에 전달
- **해결:** `series[0].type === 'pie'`도 확인하도록 isPie 조건 보정

- **문제:** E2004 — data source field inconsistent (`table_schema` 등)
- **원인:** LLM이 생성한 `argumentField`/`valueField`가 실제 쿼리 결과 컬럼명과 불일치
- **해결:** 백엔드 요청 (프론트에서 해결 불가)

## 다음 할 일

- [ ] 백엔드 SSE `done` 이벤트 신포맷 적용 확인 및 E2E 테스트
- [ ] 백엔드 E2004 수정 (LLM 차트 config 생성 시 실제 컬럼명 사용)
- [ ] Plotly 차트 초기 미렌더 이슈 (SPA 네비게이션 resize 트리거)
- [ ] PR #14 리뷰 및 머지
