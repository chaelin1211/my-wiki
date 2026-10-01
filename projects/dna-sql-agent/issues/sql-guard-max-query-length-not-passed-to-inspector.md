---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-10
resolved: true
root-cause: "설정 파일·화면에는 있는 값인데 소비처(SQLInspector) 생성 시 인자로 넘기지 않아 기본값이 쓰임"
related: [sql-guard, settings]
tags: [configuration, silent-default]
---

# `sql_guard.max_query_length` 를 바꿔도 길이 제한이 안 걸림

## 증상

`config/sql_guard.json` 의 `max_query_length` 를 낮춰도 긴 쿼리가 그대로 통과한다.
에러도 경고도 없다. 화면에서도 값은 잘 저장되고 조회된다 — 저장은 되는데 **동작만
안 한다.**

## 환경

- **관련 파일:** `src/dna/utils/sql_guard/guardrail.py`, `SQLInspector`
- **재현 조건:** `max_query_length` 를 기본값(100,000)보다 작게 설정 후 긴 쿼리 실행

## 시도한 것들

1. ❌ 설정이 로드되는지 확인 — `guard_config` 에는 값이 정상적으로 들어와 있었다
2. ✅ `SQLInspector` 생성부 확인 — 그 값을 생성자에 넘기지 않고 있었다

## 근본 원인

`check_ast_guardrail()` 이 `SQLInspector` 를 만들 때 `dialect`,
`blocked_tables`, `allowed_tables` 만 넘기고 `max_query_length` 를 빠뜨렸다.
`SQLInspector` 는 기본값을 갖고 있어서 **에러 없이 기본값으로 동작**했다.

설정이 "저장되는 곳"과 "쓰이는 곳" 사이의 연결이 끊긴 형태다. 저장·조회·화면은 모두
정상이라 문제가 드러나지 않는다. 기본값이 있는 인자일수록 조용히 지나간다.

## 해결 방법

```python
# guardrail.py — check_ast_guardrail()
 inspector = SQLInspector(
     dialect=db_dialect,
     blocked_tables=perms.get("blocked_tables", set()),
     allowed_tables=perms.get("write_allowed_tables", set()),
+    max_query_length=guard_config.get("max_query_length", 100_000),
 )
```

## 예방책

- 설정 키를 추가하면 **소비처까지 값이 닿는지**를 한 번은 실제로 확인한다. 스키마
  통과와 동작은 다른 이야기다
- 소비처에 기본값을 두면 누락이 조용해진다. 설정에서 오는 값은 가급적 기본값 없이
  넘기거나, 최소한 설정 키와 같은 상수를 공유할 것
- 설정 항목을 추가·삭제할 때 `defaults/*.json` ↔ 소비 코드를 함께 훑는다.
  이번 브랜치에서 기동 시 설정 검증을 넣은 계기 중 하나다
  → [[projects/dna-sql-agent/decisions/034-defaults-as-config-validation-spec]]

## 관련 페이지

- [[projects/dna-sql-agent/decisions/010-sql-guard-schema-qualified-block]]
- [[projects/dna-sql-agent/sessions/2026-08-13-config-spec-validation-and-docs-consolidation]]
