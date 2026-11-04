---
type: troubleshooting
project: dna-sql-agent
date: 2026-10-19
resolved: true
root-cause: "Altibase ODBC 드라이버가 결과 컬럼명을 UTF-8 바이트 단위로 넓혀 반환"
related: [dna-sql-agent-web]
tags: [altibase, odbc, pyodbc, encoding, korean, vectorization]
---

# Altibase 결과 표 한글 컬럼명 깨짐

## 증상

Altibase 연결에서 SQL을 실행하면 결과 표 헤더의 한글 컬럼명이 깨진다. 값과 영문 컬럼명, LLM 요약은 정상이다.

```
cursor.description 원본: ['LOC_NM', 'ì\x9c\x84ì¹\x98ëª\x85', 'ì¶©ì\xa0\x84ì\x9c¨(%)']
기대값:                ['LOC_NM', '위치명', '충전율(%)']
```

벡터화에서는 깨진 글자가 저장되지는 않지만, 한글 컬럼만 예시 값(`data_example`)이 빠진다. 카탈로그에서 읽은 정상 컬럼명(`위치명`)으로 표본 행에서 값을 찾는데(`row.get(col_name)`), 표본 행의 키는 깨진 이름이라 못 찾는다.

## 환경

- **런타임:** 백엔드 Docker(linux/amd64), pyodbc 5.3.0, Altibase 클라이언트 7.1.0.9.9
- **서버:** Altibase A+ Edition 7.3.0.0.7, DB 문자셋 UTF8, 연결 NLS_USE UTF8
- **재현 조건:** 한글 컬럼 또는 한글 별칭(`AS "위치명"`) 조회

## 시도한 것들

1. ❌ pyodbc `setdecoding(SQL_WMETADATA, encoding=codec)` 추가 — 가설만으로 수정. 이 가설대로면 영문 컬럼명도 깨져야 하는데 영문은 원래 정상이라 모순 → 되돌림
2. ❌ 컬럼명에 따옴표 — 따옴표 별칭·따옴표로 만든 컬럼 모두 똑같이 깨짐. 따옴표는 SQL 해석 단계 문제
3. ✅ 실서버에서 `cursor.description` 원본 확인 → 1바이트당 1글자 형태 확인 → 읽는 지점에서 복원

## 근본 원인

드라이버가 컬럼명의 UTF-8 바이트(`EC 9C 84 …`)를 바이트마다 한 글자(U+00EC, U+009C …)로 넓혀 넘긴다. ASCII는 1글자 = 1바이트라 그대로 보이고, 한글만 깨진다. 값은 `SQL_CHAR`/`SQL_WCHAR` 디코딩을 NLS_USE 코덱으로 맞춰 둬서 정상이다.

## 해결 방법

```python
def repair_column_name(name: str, codec: str) -> str:
    try:
        raw = name.encode("latin-1")   # 한 바이트 범위 글자만 → 원래 바이트
    except UnicodeEncodeError:
        return name                    # 이미 정상 한글
    if raw.isascii():
        return name                    # 영문
    try:
        return raw.decode(codec)       # 연결 NLS_USE 문자셋
    except UnicodeDecodeError:
        return name                    # café 같은 진짜 latin-1 이름
```

- `pooled_runners/altibase.py`: 결과 컬럼명 생성 시 적용(코덱은 커넥션 풀의 `charset_codec`)
- `vectorization/extractors/altibase.py`: 표본 조회 키에 적용(코덱은 오케스트레이터가 연결 정보로 전달)
- 다른 DBMS(Oracle·PostgreSQL·MySQL·SQLite)는 드라이버가 정상 유니코드를 넘겨 대상 아님(Oracle은 한글 별칭 정상 로그 확인)
- 백엔드 PR #183

## 예방책

- Altibase 실서버 통합 테스트 `test_column_aliases_read_back_intact`(영문·한글 별칭, 실패 시 코드포인트 출력)
- 인코딩 문제는 가설로 고치기 전에 드라이버 원본 값을 코드포인트로 찍어 본다
- 이미 벡터화한 Altibase 시스템은 재벡터화해야 예시 값이 채워짐

## 관련 페이지

- [[knowledge/troubleshooting/odbc-column-names-byte-widened-mojibake]]
- [[knowledge/tools/altibase-aplus-docker]]
- [[sessions/2026-10-19-altibase-korean-columns-dna-ask-links]]
