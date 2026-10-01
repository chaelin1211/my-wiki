---
type: session-log
project: dna-sql-agent
date: 2026-09-22
duration: 
focus: "SQL 예제 AI 생성 실패 수정, 차트 북마크 404 수정, 북마크 해제 보류·대시보드 삭제 안내"
tools-used: [claude-code]
outcome: success
---

# 2026-09-22 — SQL 예제 AI 생성 수정, 북마크 등록 404 수정과 해제 보류

## 목표

- SQL 예제 AI 생성이 "작업을 처리하지 못했습니다"로 실패하는 원인 수정.
- 차트 북마크 등록이 404로 실패하는 버그 수정.
- 북마크 페이지에서 해제 후 다시 북마크하면 고정이 풀리고 순서가 바뀌는 문제를 UX 관점에서 정리하고 구현.

## 수행한 작업

1. **SQL 예제 AI 생성 — task 모드 러너 작업 테이블 불일치 수정** (백엔드 `fix/collection-task-job-table`, 커밋 `7be2643`, PR 전). 작업 등록은 설정값 `sql_collection_jobs_v2`에 넣는데, task 모드 러너(`get_collection_runner`)는 `CollectionRunner()`를 인자 없이 만들어 기본값 `sql_collection_jobs`를 보고 있었음. 러너도 `resolve_sql_collection_job_table_name()`을 쓰게 맞춤. 테스트 `tests/sql_examples/test_collection_task_runner.py` 추가.
2. **AI 생성 0건 원인 설명** — 수정 후 작업은 돌지만 0건. 대상 DB의 쿼리 이력 기능이 꺼져 있었음(dnasql_agent DB: 확장은 있으나 `shared_preload_libraries`에 `pg_bigm`만). 수집기가 예외를 로그로만 남기고 빈 목록을 돌려줘 작업은 "완료 0건"으로 끝남. → [[knowledge/troubleshooting/sql-history-collection-prerequisites]]
3. **SQL 예제 수정 창 상태 라디오를 공통 `RadioGroup`으로 교체** (웹 `style/sql-example-ui`, `7acfd93`).
4. **차트 북마크 404 수정** — 원인 분석 후 서버·웹 병행 수정. → [[issues/bookmark-component-row-mismatch-404]]
   - 서버: 요청 행에 컴포넌트가 없으면 같은 대화에서 컴포넌트 id로 실제 행을 찾아 저장.
   - 웹: 행을 합쳐도 단계마다 `sourceMessageId`(실제 저장 행)를 유지해 북마크 요청에 사용.
5. **북마크 페이지 해제 보류** — 해제는 저장 전까지 대기 상태, 상단 막대에서 저장·되돌리기, 저장하지 않고 나가면 확인창(이동 가드). → [[decisions/044-bookmark-page-deferred-remove]]
6. **대시보드 삭제 안내** — 북마크 목록·참조 API에 `dashboards`(id·제목) 추가. 북마크 페이지는 카드 위 안내(카드 높이 유지)와 상단 막대의 위젯 수, 채팅 화면은 대시보드에 포함된 북마크 해제 시에만 확인창.
7. **PR** — 백엔드 #163, 웹 #94 (브랜치 `fix/bookmark-component-row`, 서로 링크).

## 핵심 결정

- **북마크 페이지 해제는 삭제를 미룬다:** 즉시 삭제 후 재생성은 id·고정·등록 시각이 바뀌고, `ON DELETE CASCADE`로 대시보드 위젯이 영구 삭제됨. 해제를 대기 상태로 두고 저장 시 일괄 삭제.
  → ADR: [[decisions/044-bookmark-page-deferred-remove]]
- **북마크 행 보정은 서버·웹 병행:** 웹이 단계별 행 id를 보내게 했지만 스트리밍 직후 단계는 행 id를 알 수 없어, 서버가 컴포넌트 id로 행을 찾는 보정을 함께 둠.

## 배운 것

- 한 답변이 DB에서 여러 행으로 나뉘어 저장되는데 화면은 한 메시지로 합치면, "메시지 id 하나"로는 그 안의 개별 컴포넌트 위치를 가리킬 수 없음. → [[knowledge/troubleshooting/merged-rows-single-id-loses-child-location]]
- 되돌릴 수 있어 보이는 토글이 실제로는 파괴적 삭제면, 연쇄 삭제(FK cascade)까지 되돌릴 수 없음. → [[knowledge/patterns/defer-destructive-toggle-until-save]]
- `pg_stat_statements`는 서버 단위(라이브러리, 재시작)와 DB 단위(확장) 설정이 따로. MariaDB는 `performance_schema`가 기본 꺼짐.

## 문제 & 해결

- **문제:** SQL 예제 AI 생성 "작업을 처리하지 못했습니다".
- **원인:** task 모드 러너가 설정된 작업 테이블이 아닌 기본 테이블을 조회.
- **해결:** 러너 생성 시 설정 테이블 이름 전달 (`7be2643`). → [[issues/log]]

- **문제:** 차트 북마크 등록 404.
- **원인:** 컴포넌트는 도구 호출 행마다 저장되는데 웹은 합친 메시지의 첫 행 id를 보냄.
- **해결:** 서버 행 보정 + 웹 단계별 행 id.
  → 이슈: [[issues/bookmark-component-row-mismatch-404]]

## 다음 할 일

- [ ] PR 백엔드 #163·웹 #94 리뷰·머지
- [ ] `fix/collection-task-job-table`(`7be2643`) PR 생성
- [ ] 수집기가 쿼리 이력 조회 실패를 로그로만 남겨 "0건 완료"로 보이는 문제 — 작업 오류로 표시할지 결정
- [ ] Postgres 수집기의 `스키마명.` 포함 필터 때문에 스키마 없이 쓴 쿼리가 모두 제외되는 문제 검토
- [ ] SQL 예제 스타일(`style/sql-example-ui`) 확인 후 항목별 커밋·PR

## 효과적이었던 프롬프트

```
원인부터 알려줘 보고 좀 하게
```
