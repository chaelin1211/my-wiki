---
type: troubleshooting
tags: [postgresql, sql, asyncpg, testing]
---

# PostgreSQL — ORDER BY 에서 출력 별칭은 단독으로만, 식 안에서는 못 쓴다

## 증상

```
asyncpg.exceptions.UndefinedColumnError: column "joined_at" does not exist
```

`SELECT ..., CASE ... END AS joined_at ... ORDER BY COALESCE(joined_at, u.created_at) DESC` 처럼 별칭을 정렬식 안에서 쓰면 난다. `ORDER BY joined_at DESC` 처럼 별칭 하나만 쓰면 된다.

## 원인

PostgreSQL 은 `ORDER BY` 항목이 **출력 칼럼 이름 하나일 때만** 별칭으로 해석한다. 식(`COALESCE(...)`, `x + 1` 등)의 일부로 쓰면 입력 테이블 칼럼으로 찾다가 없다고 한다. (`WHERE`·`GROUP BY` 의 식에서도 별칭은 못 쓴다.)

## 해결

- 정렬식에 계산식 자체를 넣는다. 같은 식을 여러 곳에서 쓰면 파이썬 상수로 두고 f-string 으로 끼운다.

```python
_JOINED_AT_SQL = "CASE WHEN u.status IN ('pending','rejected') THEN NULL WHEN u.review_result = 'approved' THEN u.reviewed_at ELSE u.created_at END"
order_by = f"COALESCE({_JOINED_AT_SQL}, u.created_at) DESC, u.id"
```

- 또는 서브쿼리/CTE 로 감싸 바깥에서 별칭을 칼럼처럼 쓴다.

## 교훈

가짜 DB 커넥션으로 쿼리 문자열만 확인하는 단위 테스트는 이런 SQL 문법 오류를 못 잡는다. 쿼리를 바꾸면 **실제 DB로 그 함수를 한 번 불러** 확인한다(읽기 전용이면 바로, 쓰기면 트랜잭션 후 ROLLBACK).

## 같이 만난 것 — asyncpg 파라미터 타입 충돌

같은 파라미터(`$1`)를 `status = $1` 과 `CASE WHEN $1 = 'active'` 에 함께 쓰면 `AmbiguousParameterError: inconsistent types deduced for parameter $1 (text versus character varying)` 가 난다. `$1::varchar` 처럼 타입을 명시한다.

## 관련

- [[projects/dna-sql-agent/sessions/2026-10-19-auth-enhancement-signup-reset-account-management]]
