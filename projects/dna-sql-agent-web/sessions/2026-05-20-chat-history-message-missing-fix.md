---
type: session-log
project: dna-sql-agent-web
date: 2026-05-20
duration: 
focus: "이전 대화 로드 시 단순 응답 메시지 누락 버그 수정"
tools-used: [claude-code]
outcome: success
---

# 2026-05-20 — 이전 대화 로드 시 단순 응답 메시지 누락 버그 수정

## 목표

이전 대화 로드 시 단순 한 줄 응답(예: "안녕하세요!")이 화면에 표시되지 않는 버그 수정

## 수행한 작업

1. 버그 재현 및 원인 분석
   - 메시지 JSON 구조 확인: `content` 필드 + `components[]` 배열 구조
   - `lib/build-steps.ts`의 `buildStepsFromMessage` 코드 추적
   - `isLikelyResponseText` 휴리스틱이 마크다운/줄바꿈 없는 단순 텍스트를 드랍하는 것 확인
2. `lib/build-steps.ts` 수정: `isLikelyResponseText` 조건 제거, `!hasTextStep`만으로 처리
3. `docs/chat-design.md` 섹션 11 내용 갱신
4. 커밋 및 PR #4 생성 (`fix/chat-history` → `main`)
   - 검토자: smseokr, maniakim-mobigen
   - 담당자: chaelin01211

## 핵심 결정

- `isLikelyResponseText` 휴리스틱 제거: 중복 방지는 이미 `hasTextStep`으로 보장되므로 추가 필터링 불필요
  → 이슈: [[issues/chat-history-message-missing]]

## 배운 것

- 메시지 `components`가 status/task 관련 업데이트만 포함할 경우 text step이 생성되지 않음
- 이 경우 `m.content`가 유일한 텍스트 소스인데, `isLikelyResponseText`가 단순 한 줄 텍스트를 잘못 필터링했음
- `onText` 콜백은 `simple.type === 'text'` 또는 `richType === 'text'`일 때만 호출됨
- `chat_input_update`는 `processChunk`에서 명시적으로 무시됨 (249번 줄)

## 문제 & 해결

- **문제:** 이전 대화 로드 시 단순 한 줄 응답이 화면에 표시되지 않음
- **원인:** `isLikelyResponseText` 휴리스틱이 마크다운 기호나 줄바꿈이 없는 텍스트를 모두 드랍
- **해결:** 조건 제거, `!hasTextStep`이면 무조건 `m.content` 표시
  → 이슈: [[issues/chat-history-message-missing]]

## 다음 할 일

- [ ] PR #4 리뷰 및 머지
- [ ] Connections status 토글 깜빡임 수정 (옵티미스틱 업데이트)
- [ ] UI: 접근 불가 메뉴 표시 제거
- [ ] 채팅 목록 제목 수정 / 최신 업데이트 기준 정렬
