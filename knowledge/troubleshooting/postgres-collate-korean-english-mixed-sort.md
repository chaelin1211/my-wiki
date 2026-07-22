---
type: knowledge
category: troubleshooting
date: 2026-07-22
tags: [postgresql, i18n, sorting, sql]
---

# PostgreSQL — 한글/영문 혼용 텍스트 정렬이 기대와 다르게 나옴

## 문제 패턴

이름 컬럼(연결명, 시스템명, 그룹명, 사용자명 등)에 한글과 영문이 섞여 있을 때
`ORDER BY name`을 쓰면 사용자가 기대하는 "가나다순/알파벳순이 자연스럽게 섞인"
순서가 아니라, DB 기본 정렬 로케일의 코드포인트 순서로 정렬되어 뒤죽박죽으로
보인다. 같은 화면 안에서도 목록마다(연결/시스템/그룹/권한 등) 증상이 개별
버그처럼 보이지만, 근본 원인은 대부분 하나다.

## 원인

DB(또는 컬럼/데이터베이스)의 기본 collation이 `C`이거나 특정 단일 로케일로
고정되어 있으면, 여러 언어가 섞인 문자열을 사람이 기대하는 방식으로 정렬하지
못한다.

## 해결

정렬이 필요한 `ORDER BY` 절에 ICU 기반 언어 중립 collation을 명시:

```sql
SELECT * FROM connections ORDER BY name COLLATE "und-x-icu";
```

SQLAlchemy에서는 `func.collate` 또는 컬럼에 직접 명시:

```python
query.order_by(func.collate(Connection.name, "und-x-icu"))
```

## 진단 팁

- 화면 여러 곳(목록 A, 목록 B, 목록 C…)에서 "정렬이 이상하다"는 리포트가
  거의 동시에 들어오면, 각각 따로 고치기 전에 공통 원인(collation)부터
  의심할 것.
- PostgreSQL 서버에 ICU 확장이 설치되어 있어야 `und-x-icu` collation을 쓸 수
  있다(최신 PostgreSQL은 기본 포함되는 경우가 많음) — 없으면 `\dOS`로 사용
  가능한 collation 목록 확인.

## 실제 사례

- [[projects/dna-sql-agent/sessions/2026-07-22-group-admin-hardening-and-pr117]]
  — 연결/시스템/그룹/사용자 권한 목록 등 다수 지점에서 반복 발견, 한 번에
  `COLLATE "und-x-icu"` 적용으로 일괄 해결
