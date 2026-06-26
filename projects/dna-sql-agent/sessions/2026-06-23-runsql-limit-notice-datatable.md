---
type: session-log
project: dna-sql-agent
date: 2026-06-23
duration:
focus: "run_sql LIMIT 자동 주입 고지 및 DataTable 정렬·sticky 헤더"
tools-used: [claude-code]
outcome: success
---

# 2026-06-23 — run_sql LIMIT 자동 주입 고지 및 DataTable 개선

## 목표

- 대시보드 새로고침 시 4만 행을 전체 조회하던 부하 문제 해결
- estimator가 실행 직전 주입하는 LIMIT을 화면·LLM·북마크에 일관되게 반영
- 채팅 내 table 시각화(DataTable) UX 개선 (낮은 높이, 정렬 없음, sticky 미동작)

## 수행한 작업

1. **백엔드 — run_sql LIMIT 자동 주입 고지** (`validated_run_sql.py`)
   - estimator가 `args.sql`에 LIMIT을 주입하면, 실행된 SQL을 로그(LogEntry)로 표시
   - `result_for_llm` **앞에** LIMIT 적용 고지를 prepend → LLM이 `visualize_data` 제목 생성 전에 인지하도록
2. **백엔드 — 북마크 query_sql에 LIMIT 반영** (`bookmarks/routes.py`)
   - `create_bookmark` 시점에 `estimator._inject_limit()` 적용 후 저장
   - 근본 원인: `tool_calls`는 LLM 응답(도구 실행 *전*)에서 저장되므로 `tool_calls.arguments.sql`엔 LIMIT이 없음. `_extract_query_info`가 이걸 읽어 `query_sql`에 LIMIT 없는 SQL 저장 → render_bookmark가 전체 조회
3. **프론트엔드 — DataTable 개선** (`data-table.tsx`, `echarts-chart-block.tsx`, `bookmark-view.tsx`)
   - 컬럼 헤더 클릭 정렬(숫자·문자 자동 판별), SortIcon 추가
   - sticky 헤더: shadcn `<Table>`이 내부적으로 `div.overflow-x-auto` 래퍼를 만들어 `th.sticky.top-0`이 깨짐 → plain `<table>`로 교체 (flat·non-flat 양쪽)
   - `bg-muted/60`(반투명) → `bg-muted`(불투명)로 스크롤 시 헤더 내비침 제거
   - 높이: non-flat 모드에도 chartHeight 전달, 북마크 확장/일반 모드 높이 정합, 10행 제한 해제
4. **커밋 정리 & PR**
   - 작업 중 추가했던 "히스토리 dataframe 200행 truncation"은 사용자 요청이 아니어서 제거 (조회 시 LIMIT으로 이미 방어됨)
   - 백엔드 커밋 4개(추가→수정→되돌리기 상쇄)를 `git reset --soft main`으로 단일 커밋 squash 후 force push
   - PR #77 (백엔드), PR #56 (프론트엔드) 생성

## 핵심 결정

- **LIMIT 고지를 `result_for_llm` 끝이 아닌 앞에 prepend:** 끝에 붙이면 LLM이 이미 제목 방향을 정한 뒤라 "전체 데이터 조회" 같은 제목이 나옴
- **북마크는 저장 시점에 LIMIT 주입:** 실행 시점 주입(`args.sql`)은 `tool_calls`에 반영 안 되므로, 기록 경로(create_bookmark)에 별도로 적용

## 배운 것

- estimator의 LIMIT은 도구 실행 직전 `args.sql`에 주입되지만, `tool_calls`는 그보다 먼저 LLM 응답에서 저장되어 둘이 불일치한다. 실행 SQL과 기록 SQL이 갈라지는 구조.
- shadcn/ui `Table` 컴포넌트는 `<table>`을 `div[data-slot="table-container"].overflow-x-auto`로 감싼다. 이 스크롤 컨테이너가 `position: sticky` 헤더의 기준을 가로채서 sticky가 동작하지 않는다. → 스크롤 컨테이너를 직접 제어하려면 plain `<table>` 사용.

## 문제 & 해결

- **문제:** 북마크 기반 대시보드 새로고침 시 LIMIT 없이 전체(4만 행) 조회
- **원인:** `query_sql`이 `tool_calls.arguments.sql`(도구 실행 전, LIMIT 미주입)에서 추출됨
- **해결:** `create_bookmark`에서 `_inject_limit` 적용
  → 이슈: [[issues/bookmark-query-sql-limit-not-injected]]

- **문제:** DataTable sticky 헤더가 스크롤 시 고정되지 않음
- **원인:** shadcn `<Table>`의 `overflow-x-auto` 래퍼가 sticky 기준 컨테이너를 가로챔
- **해결:** plain `<table>`로 교체 + `bg-muted` 불투명 배경
  → 트러블슈팅: [[knowledge/troubleshooting/shadcn-table-sticky-header-overflow-wrapper]]

## 다음 할 일

- [ ] PR #77, #56 리뷰 및 머지
- [ ] 기존 북마크(LIMIT 없는 query_sql) 마이그레이션 또는 render 시 LIMIT 주입 검토

## 효과적이었던 프롬프트

```
(사용자가 근본 원인을 정확히 짚음)
"실제는 채팅할 때 쿼리 자체에 1000건 제한을 내부적으로 하고 있는데
그게 실행 직전에 붙어서 북마크 db에 저장되는 쿼리에는 반영이 안 되더라고.
그래서 쿼리 실행 전이 아니라 기록할 때 자체에 붙어야 할 거 같아."
```
