---
type: session-log
project: dna-sql-agent
date: 2026-09-22
duration: 2일 (2026-09-21 ~ 09-22)
focus: "슬래시 커맨드 — DB 등록형 커맨드, 입력창 목록, 기본 커맨드 한글화"
tools-used: [claude-code, claude-in-chrome]
outcome: success
---

# 2026-09-22 — 슬래시 커맨드 (DB 등록형)

## 목표

채팅 입력창에서 `/`를 치면 쓸 수 있는 커맨드 목록이 보이게 한다. 기존에는 `/help`와 관리자용 몇 개가 코드 조건문에만 있어 목록을 보여 줄 수 없었다.

## 수행한 작업

1. 현재 구조 분석 — 커맨드는 `DefaultWorkflowHandler.try_handle`의 조건문에 하드코딩, 별칭(`help`, `status` 등)이 일반 질문을 가로채고, 미등록 `/foo`는 LLM으로 넘어가는 상태였다.
2. 설계 문서 작성 — `docs/design/chat/slash-command-design.md`. 기능 동작과 모순 점검 위주의 가이드형 문서로, 구현 후 코드와 맞춰 계속 갱신했다.
3. 백엔드 구현 (`feat/slash-command`, PR #162)
   - `slash_commands` 테이블과 기본 커맨드 4종 시드, 해석·권한·실행 서비스, 조회 API와 관리자 CRUD API.
   - LLM을 건너뛴 커맨드 턴도 대화 이력에 저장하도록 `WorkflowResult`·`agent.py` 확장, 스킬 메타데이터 저장과 LLM 직전 블록 펼침 필터, 대화 요약·메모리 검색어 처리, 커맨드 감사 이벤트.
   - `/help`(서비스 안내 + 현재 시스템 예시 질문 버튼), `/status`(도구 설정 기준 표), `/memories`(목록 컴포넌트), `/delete` 출력 한글화.
4. 웹 구현 (`feat/slash-command`, PR #93)
   - 입력창 커맨드 목록(문장 중간 `/` 지원, 선택 시 커맨드를 맨 앞으로 이동, 일치 없으면 닫기).
   - 버튼을 도구 호출 과정으로 분류하지 않게 수정, 새로고침 시 본문 뒤 버튼 순서 유지, `item_list` 목록 컴포넌트, outline 버튼, 후속 질문 `→` 목록 스타일.
5. 곁가지 수정 — 답변 HTML 태그 금지 규칙, 후속 질문 템플릿의 중괄호 자리표시자 제거.
6. 로컬 테스트용 커맨드 등록 — `admin-guide`(관리자·text), `data-tour`(공용·skill). 개발 DB에만 있음.
7. SQL 예제 관리 화면 스타일 작업 착수(`style/sql-example-ui`) — 슬래시 PR을 먼저 올리기 위해 커밋 전 상태로 stash 보관.

## 핵심 결정

- **커맨드 정의는 DB에, 실행 로직만 코드에:** builtin·text·skill 세 방식, public·admin 공개 범위. `.md` 파일 방식은 형식 강제·다중 서버·사용자 생성 확장에서 불리해 기각.
  → ADR: [[decisions/041-slash-commands-db-registry]]
- **스킬 턴은 원문 저장 + 지시문 스냅샷, LLM 직전에만 블록으로 펼침:** 제목·검색·취소 저장·화면 표시가 모두 원문을 보게 하고, 스킬을 고쳐도 진행 중 대화 맥락 불변.
  → ADR: [[decisions/042-skill-turn-snapshot-and-llm-expansion]]
- **커맨드 결과는 카드·마크다운 링크 대신 전용 컴포넌트:** 카드는 웹이 도구 결과로 접고, 텍스트와 컴포넌트를 섞으면 새로고침 때 순서가 바뀐다.
  → ADR: [[decisions/043-command-result-dedicated-component]]
- 모든 커맨드는 대화 이력에 저장하되 LLM 맥락에는 스킬만, 모든 실행은 감사 로그에 남긴다.
- `/status`의 도구 목록·구분은 코드에 두지 않고 `tool_access` 설정과 기본값에서 읽는다.
- 권한 밖 커맨드도 "알 수 없는 커맨드"로 응답해 관리자 커맨드 존재를 드러내지 않는다.

## 배운 것

- 턴 번호를 세는 곳(턴 캡·존별 압축·대화 요약 `chunk_end`)이 여럿이면, 일부 턴을 LLM 맥락에서 빼는 필터는 반드시 필터 목록 마지막에 두고 턴은 그대로 세야 요약 구간이 어긋나지 않는다.
- LLM을 건너뛰는 경로는 `after_message` 훅도 건너뛰므로, 대화 저장이 훅에 걸려 있으면 그 경로의 턴은 통째로 유실된다.
- 웹은 새로고침 시 저장된 컴포넌트를 먼저 그리고 본문 텍스트를 뒤에 붙인다. 텍스트와 컴포넌트를 섞은 응답은 실시간과 새로고침 화면이 달라진다.
- 프롬프트 템플릿에 무엇을 보여 주든 모델은 그 모양을 베낀다(예시 문장 → `< >` → `{ }` → 자리표시자 글자 순으로 반복).
  → [[knowledge/prompting/llm-copies-template-placeholders]]

## 문제 & 해결

- **문제:** 기존 대화에서 builtin 커맨드를 실행하면 결과 카드가 직전 질문의 답변 아래에 붙어 복원됨.
- **원인:** 커맨드 사용자 메시지를 저장하지 않아 컴포넌트 저장 미들웨어가 "마지막 사용자 메시지 이후 assistant 행"으로 직전 턴을 잡음.
- **해결:** 커맨드 턴도 저장하고 사용자 메시지 행을 스트림 종료 전에 기록.
  → 이슈: [[issues/workflow-short-circuit-components-attach-to-previous-answer]]
- 그 밖의 사소한 문제는 [[issues/log]]에 한 줄씩 기록.

## 다음 할 일

- [ ] PR 백엔드 #162·웹 #93 리뷰·머지
- [ ] `dnasql-agent` 대화에서 시스템 범위가 비어 `/memories`가 전체 시스템 메모리를 필터 없이 보여 준 원인 추적
- [ ] 후속 질문이 "후속 질문 문장"을 그대로 베끼는 경우 확인 — 재발하면 서버에서 링크 글자 정리
- [ ] `style/sql-example-ui` stash 복원 후 dev 서버 재시작해 SQL 하이라이트 공통 색(`globals.css`) 반영 확인, 커밋·PR
- [ ] 테스트용 커맨드 `admin-guide`·`data-tour` 정리 여부 결정

## 효과적이었던 프롬프트

```
설계 문서는 구현 위주가 아니라 기능이 어떻게 동작되고 거기에 모순이 없는지를 점검하기 위한 거니까 상세하게 적고, 가이드 문서에 가깝게 해줘
```
