---
type: troubleshooting
tags: [odbc, pyodbc, encoding, mojibake, korean]
created: 2026-10-19
updated: 2026-11-03
---

# ODBC 결과 컬럼명이 바이트 단위로 넓혀져 한글만 깨진다

## 증상

값은 정상인데 `cursor.description`의 컬럼명만 깨진다. 영문 컬럼명은 멀쩡하고 한글만 `ìœ„ì¹˜ëª…` 같은 모양이 된다.

```python
[d[0] for d in cursor.description]
# ['LOC_NM', 'ì\x9c\x84ì¹\x98ëª\x85']   ← '위치명'
```

## 판별법

깨진 문자열의 코드포인트가 **모두 `0x00`~`0xFF`이고**, 그 값을 바이트로 모으면 올바른 UTF-8(또는 CP949)이 된다.

```python
name.encode("latin-1").decode("utf-8")   # → '위치명' 이면 이 경우
```

드라이버가 컬럼명 바이트를 바이트마다 한 글자로 넓혀(latin-1처럼) 와이드 문자열에 채워 넘기는 것이다. ASCII는 1글자 = 1바이트라 결과가 같아서 영문은 안 깨진다.

## 하면 안 되는 것

- **드라이버 메타데이터 디코딩 설정 변경**(pyodbc `setdecoding(SQL_WMETADATA, ...)`) — 영문이 정상이라는 건 와이드 문자열 자체는 제대로 온다는 뜻이다. 디코딩을 바꾸면 영문까지 깨질 수 있다. 가설을 세웠다면 "영문은 왜 멀쩡한가"로 먼저 검증한다.
- **컬럼명·별칭에 따옴표** — SQL 해석 단계 문제라 반환 컬럼명 인코딩과 무관하다.

## 해결

컬럼명을 읽는 지점에서 **깨진 형태일 때만** 되돌린다.

```python
def repair_column_name(name, codec):
    try:
        raw = name.encode("latin-1")
    except UnicodeEncodeError:
        return name          # 이미 정상(한 바이트 범위 밖 글자 포함)
    if raw.isascii():
        return name
    try:
        return raw.decode(codec)   # 연결 문자셋(UTF8/MS949/EUC-KR)
    except UnicodeDecodeError:
        return name          # café 같은 진짜 latin-1 이름
```

결과 컬럼명을 읽는 곳이 여러 군데면(쿼리 실행, 스키마 추출의 표본 조회 등) 모두 적용한다. 컬럼명을 딕셔너리 키로 쓰는 곳은 깨져도 에러 없이 조용히 매칭이 실패한다.

## 근본 원인: 드라이버에 W 함수가 없을 때 unixODBC가 로케일을 보고 변환

드라이버가 `SQLDescribeColW` 같은 W(UTF-16) 함수를 제공하지 않으면 unixODBC가 ANSI 함수 결과를 받아 변환을 대신한다. 이때 unixODBC는 바이트 인코딩을 프로세스 로케일(`nl_langinfo`)에서 읽고, 길이는 드라이버가 준 바이트 수를 그대로 쓴다.

- 로케일이 `C`: 바이트를 한 칸씩 넓혀 넘김. 길이가 맞고 위의 복원 함수로 정확히 돌아온다.
- 로케일이 `C.UTF-8`: 어떤 계기(예: 프로세스 안에서 다른 연결이 닫힘) 뒤부터 UTF-8을 제대로 UTF-16으로 바꾸면서 길이는 바이트 수 그대로 넘겨, 이름 뒤에 NUL·쓰레기가 붙는다. 증상은 CSV 저장의 `need to escape, but no escapechar set`, 또는 `UnicodeDecodeError: 'utf-16-le'`.

판별: `nm -D --defined-only <드라이버.so> | grep SQLDescribeColW`가 비어 있으면 이 경우. unixODBC 추적(`/etc/odbcinst.ini`의 `[ODBC] Trace=Yes`)으로 연결별 차이를 볼 수 있다.

해결: 컨테이너에서 `LC_ALL=C`로 변환 자체를 막고 Python은 `PYTHONUTF8=1`로 UTF-8 유지. unixODBC 2.3.12에는 변환 인코딩을 ini로 지정하는 설정이 없다. 접속 문자셋을 DB와 다른 MS949 등으로 바꾸는 우회는 표현 못 하는 문자가 조용히 `?`가 된다.

서버 오류 메시지에 반향된 SQL의 한글도 같은 방식으로 넓혀져 오므로 같은 복원을 적용한다.

## 사례

- Altibase ODBC 7.1 + pyodbc 5.3 — [[projects/dna-sql-agent/issues/altibase-odbc-korean-column-names-byte-widened]]
- Altibase 7.1 클라이언트 + unixODBC 2.3.12 로케일 원인 — [[projects/dna-sql-agent/issues/altibase-utf8-locale-column-name-nul]]
