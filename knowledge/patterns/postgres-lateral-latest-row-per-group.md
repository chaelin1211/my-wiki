---
type: knowledge
category: patterns
tags: [postgresql, sql, lateral-join, asyncpg]
created: 2026-05-26
---

# PostgreSQL — 그룹별 최신 1건 조회 (LATERAL JOIN)

## 패턴

목록 조회 시 각 부모 행에 대해 자식 테이블에서 최신(또는 특정 조건의) 1건만 가져올 때 사용.

```sql
SELECT parent.id, parent.title,
       child_latest.content AS last_message
FROM parent_table parent
LEFT JOIN LATERAL (
    SELECT content
    FROM child_table
    WHERE parent_id = parent.id
      AND role = 'assistant'   -- 조건 필터 (없으면 생략)
    ORDER BY created_at DESC
    LIMIT 1
) child_latest ON TRUE
WHERE parent.user_id = $1
ORDER BY parent.updated_at DESC
LIMIT $2 OFFSET $3
```

- `LEFT JOIN LATERAL … ON TRUE` — 자식 행이 없으면 NULL 반환 (INNER JOIN이면 부모 행 자체가 탈락)
- `ON TRUE` — LATERAL 서브쿼리는 ON 조건이 항상 참이므로 관용적으로 `ON TRUE` 사용

## 주의

- `COUNT(*) OVER()` 윈도우 함수는 LATERAL JOIN 추가 후에도 부모 테이블 기준으로 카운트됨 → `total` 집계에 영향 없음
- asyncpg에서 LATERAL 결과 컬럼은 `row["컬럼명"]`으로 직접 접근 가능

## 대안 비교

| 방법 | 특징 |
|------|------|
| LATERAL JOIN | 단일 쿼리, DB 부담 집중, N+1 없음 |
| 별도 쿼리 (IN 절) | 코드 복잡도 증가, 두 번 왕복 |
| 애플리케이션 레벨 조합 | N+1 문제 발생 가능 |

## 사용 사례

- `dna-sql-agent`: `GET /api/v1/chat` — 각 대화의 마지막 assistant 메시지를 `last_message`로 반환