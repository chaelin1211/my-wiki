---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-23
resolved: true
root-cause: "tool_calls는 도구 실행 전 LLM 응답에서 저장되어 estimator의 런타임 LIMIT 주입이 반영되지 않음"
related: [bookmark, estimator, dashboard]
tags: [bookmark, limit, estimator, dashboard]
---

# 북마크 query_sql에 LIMIT이 반영되지 않아 대시보드 새로고침 시 전체 조회

## 증상

북마크 기반 대시보드를 새로고침하면 LIMIT 없이 전체(약 4만 행) 테이블을 조회해 부하가 큼.
채팅에서 run_sql 도구로 볼 땐 LIMIT이 안 보이지만, 실제로는 실행 직전에 LIMIT이 붙어 1000건만 조회되고 있었다.

## 환경

- **런타임:** Python 3.10, FastAPI
- **관련 모듈:** `validated_run_sql.py`(estimator), `bookmarks/routes.py`(create_bookmark, _extract_query_info), render_bookmark
- **재현 조건:** 대용량 테이블을 조회한 채팅 결과를 북마크 → 대시보드 위젯으로 추가 후 새로고침

## 시도한 것들

1. ❌ render_bookmark에서 fetch 후 행 수 제한 → DB는 여전히 전체 조회 (부하 그대로)
2. ✅ create_bookmark 저장 시점에 LIMIT 주입 → 기록 SQL 자체에 LIMIT 포함

## 근본 원인

estimator는 도구 실행 직전 `args.sql`에 LIMIT을 주입한다(`args.sql = estimate_result.modified_sql`).
그러나 `messages.tool_calls`는 **LLM 응답(도구 실행 전)** 에서 저장되므로 `tool_calls.arguments.sql`엔 LIMIT이 없다.
`_extract_query_info`가 이 `tool_calls.arguments.sql`을 읽어 `bookmarks.query_sql`에 저장 → render_bookmark가 LIMIT 없는 SQL을 재실행.

즉, **실행 SQL과 기록 SQL이 갈라지는** 구조였다.

## 해결 방법

`create_bookmark`에서 저장 전 estimator의 `_inject_limit`을 동일하게 적용:

```python
if query_sql and row["connection_name"]:
    conn_ctx = await database_pool.get_context(row["connection_name"])
    config = _settings_manager.load("estimator")
    if config.get("enabled", True) and conn_ctx.estimator:
        query_sql = conn_ctx.estimator._inject_limit(query_sql)
```

추가로 run_sql 도구 자체에서도 LIMIT 주입 시 실행 SQL을 로그로 표시하고,
`result_for_llm` 앞에 LIMIT 고지를 prepend해 LLM이 시각화 제목에 전수 조회 표현을 쓰지 않도록 함.

## 예방책

- 런타임에 변형되는 SQL(estimator/guard 등)은 "실행 경로"와 "기록 경로"가 갈라질 수 있음을 항상 의식.
- `tool_calls`는 LLM 응답 스냅샷이지 실제 실행 인자가 아니다 — 실행 결과를 기록하려면 별도 경로에서 동일 변형을 재적용하거나, 실행 후 인자를 기록해야 함.

## 관련 페이지

- 세션: [[projects/dna-sql-agent/sessions/2026-06-23-runsql-limit-notice-datatable]]
- ADR: [[projects/dna-sql-agent/decisions/015-bookmark-dashboard-architecture]]
