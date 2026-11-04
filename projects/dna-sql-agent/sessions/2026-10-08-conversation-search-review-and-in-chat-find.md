---
type: session-log
project: dna-sql-agent
date: 2026-10-08
duration: 2026-10-06 ~ 2026-10-08
focus: "대화 검색 기능 검토, 결과 위치 이동 수정, 대화 내 검색(찾기) 추가"
tools-used: [claude-code]
outcome: success
---

# 2026-10-08 — 대화 검색 검토와 대화 내 검색 추가

## 목표

대화 검색 기능(백엔드 `POST /api/v1/chat/search`, 웹 검색창·대화 내 이동)을 검토하고, 실제로 불편한 부분을 고친다.

## 수행한 작업

1. 검색 기능 검토. 권한 범위(본인 대화만)와 SQL 인젝션은 문제없음. 실제 문제는 "백엔드가 세는 메시지"와 "화면의 말풍선"이 다르다는 점으로 정리.
   - 검색 결과로 연 대화가 답변에만 일치하면 해당 위치로 이동하지 않음 (개발 DB 응답 240,822건 중 98%가 여러 행으로 나뉘어 저장).
   - 접힌 "도구 호출 과정" 설명 글까지 검색되고 일치 수가 부풀려짐 (7,945건).
   - 검색 결과 20개 이후를 볼 수 없음.
   - 검색어 길이 제한이 없어 20,000자에서 PostgreSQL `regular expression is too complex` → 500.
2. 결과 위치 이동 수정. 합친 말풍선이 단계별 `sourceMessageId`로 원래 행 id를 모두 갖고 있으므로, 이동 대상·강조 판정을 "이 말풍선이 그 행을 포함하는가"로 변경 → [[issues/search-target-merged-message-row-id]].
3. 대화 내 검색어 하이라이트. 처음에는 CSS Custom Highlight API를 제안했다가 렌더링 시 `<mark>`(텍스트는 직접, 답변 마크다운은 rehype 플러그인)로 변경. 이후 브라우저 찾기와 같게 일치 전체는 노랑, 현재 위치는 주황 → [[projects/dna-sql-agent-web/decisions/018-in-chat-search-highlight-render-time-mark]].
4. 대화 내 검색 바 개선. 검색어를 고쳐 다시 검색(Enter·Shift+Enter·Esc, 한글 조합 중 Enter 무시), 결과 없음에도 바 유지, 이동 버튼 순환(결과 1개도 재이동), 연 메시지에 일치가 없으면 다른 메시지를 칠하지 않고 `–/N` 표시.
5. 채팅 헤더 돋보기(오른쪽 아이콘 묶음 맨 앞)로 전체 검색 없이 대화 내 검색 열기. 첫 일치는 화면 맨 위에 보이는 메시지부터.
6. 대화 검색창 깜빡임 제거. 새 결과가 올 때까지 이전 결과 유지, 로딩 화면은 300ms 넘을 때만 → [[knowledge/patterns/keep-stale-results-while-loading]].
7. 띄어 쓴 영어 검색어 0건 수정. 검색어 공백을 지우고 한글 옆에만 `\s*`를 넣던 규칙이라 "sales report"가 `salesreport`가 됨. 검색어에 띄어 쓴 자리에도 `\s*` 허용(서버·웹 동일 규칙).
8. 검색창 시스템 이름을 채팅 목록과 같은 표시명으로. 시스템은 `(connection_name, system_name)` 쌍으로만 고유해서 검색 결과에 `connection_name` 추가.
9. 웹 저장소 주석 규칙(고객사 산출물, 의도 설명 주석 금지) 위반 22줄 정리 후 PR.
10. PR: 백엔드 #175(`fix/search-ascii-word-spacing`, 커밋 2개), 웹 #100(`fix/search-target-merged-message`, 커밋 9개). 두 PR 함께 배포 필요.

## 핵심 결정

- **본문 하이라이트는 렌더링 시 `<mark>`:** 검색창 미리보기와 같은 스타일·모든 브라우저 지원·테스트 가능. 브라우저 방식(Highlight API)은 서식 경계 일치와 무재렌더가 장점이지만 DOM 동기화를 직접 해야 함.
  → ADR: [[projects/dna-sql-agent-web/decisions/018-in-chat-search-highlight-render-time-mark]]
- **여러 단어 검색(OR/AND)은 보류:** 현재는 "구절 일치"(서울 김포 → 붙어 있거나 띄어쓰기만 다른 경우). OR 설계(포함 단어 수 → 구절 → 제목 단어 수 → 일치 메시지 수 → 최신순, 단어 1개는 기존 SQL)와 실측(최다 계정 2단어 +25~40%)까지 해 두고 사용자 결정으로 유지.
- **시스템 식별은 당분간 이름 쌍, 근본적으로는 `system_id` 저장:** `conversations`에 시스템 ID가 없어 채팅 목록과 같은 이름 쌍 기준으로 맞춤. 대화에 `system_id`를 저장하는 작업은 별도로 진행.

## 배운 것

- 화면이 여러 저장 행을 한 항목으로 합치는 구조에서는 "서버가 가리킨 행 id"와 "화면 항목 id"가 어긋나는 문제가 반복된다. 9/22 북마크 404에 이어 검색 이동에서 재발 → [[knowledge/troubleshooting/merged-rows-single-id-loses-child-location]].
- prop에서 파생한 state를 effect로 동기화하면 한 렌더 늦게 반영되어, 같은 렌더에서 "한 번만 실행" 로직이 이전 값으로 계산된다 → [[knowledge/patterns/sync-derived-state-during-render]].
- `::highlight()`는 배경·글자색 정도만 지원하지만 사각형·여백 없는 스타일이면 충분하다. 선택 기준은 스타일보다 DOM 동기화 비용.
- 웹 저장소 CLAUDE.md는 백엔드와 주석 규칙이 다르다(고객사 산출물). 작업 시작 전에 저장소별 규칙을 먼저 확인할 것.

## 문제 & 해결

- **문제:** 답변에만 있는 단어로 검색한 결과를 열면 이동·강조 없음.
- **원인:** 웹이 응답의 여러 행을 한 말풍선으로 합치며 첫 행 id만 남김. 서버의 `first_message_id`는 실제 일치한 최종 답변 행.
- **해결:** 말풍선이 단계별 원래 행 id 중 하나라도 가지면 대상으로 판단.
  → 이슈: [[issues/search-target-merged-message-row-id]]
- **문제:** 띄어 쓴 영어 검색어 0건, 검색창 깜빡임, 시스템 내부 이름 노출 → [[issues/log]] 및 위 작업 내용.

## 다음 할 일

- [ ] 백엔드 #175·웹 #100 리뷰·머지 (함께 배포)
- [ ] 백엔드 `ruff format --check`·`ruff check` (로컬에 ruff 없어 미실행, CI 확인)
- [ ] 대화에 `system_id` 저장 (마이그레이션·backfill·저장 훅·목록/상세/검색 API·웹 표시)
- [ ] 영어 붙여 쓴 검색어("salesreport")로 띄어 쓴 본문 찾기 여부 — 노이즈 측정 후 결정
- [ ] 여러 단어 검색 OR/AND 결정 (설계·실측 완료)
- [ ] 접힌 "도구 호출 과정" 글 검색 제외 여부 (검색 결과와 대화 내 일치 불일치 원인)
- [ ] 검색 결과 20개 이후 "더 보기"
- [ ] 실시간 대화의 `reconcileBackendMessageIds`가 응답당 assistant 행 하나를 전제 — id 밀림 여부 검증
- [ ] 설계 문서 갱신 (백엔드 §5 일치 규칙, 웹 대화 내 검색·하이라이트·헤더 진입점)

## 효과적이었던 프롬프트

```
진짜 그게 최선의 방법이야? 너가 퍼블리셔면 그렇게 하자 할거야?
```

구현 편의로 고른 방식을 사용자·퍼블리셔 관점에서 다시 따져 보게 만들어, Highlight API → `<mark>` 전환으로 이어짐.
