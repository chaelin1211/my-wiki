---
type: troubleshooting
project: dna-sql-agent
date: 2026-11-03
resolved: true
root-cause: "UTF-8 로케일에서 unixODBC가 W 함수 없는 Altibase 드라이버의 한글 컬럼명을 UTF-16으로 변환하며 길이를 바이트 수로 넘김"
related: [altibase-odbc-korean-column-names-byte-widened]
tags: [altibase, odbc, unixodbc, locale, pyodbc]
---

# Altibase 데이터 탐색이 가끔 `need to escape`·`utf-16-le`로 연달아 실패

## 증상

```
Error executing query: need to escape, but no escapechar set
Error executing query: Altibase query failed (SQLSTATE=unknown): utf-16-le
```

어느 순간부터 같은 오류가 반복되고 도구 호출 초과로 끝난다. 커넥션 NLS_USE를 바꿔 저장하면 회복된다.

## 환경

- **런타임:** 앱 컨테이너(python 3.10, pyodbc 5.3.0, unixODBC 2.3.12), Altibase ODBC 클라이언트 7.1.0.9.9
- **DB:** 운영 Altibase 7.1.0.10.6(UTF8), 로컬 재현 A+ 7.3(UTF8)
- **재현 조건:** NLS_USE=UTF8, 프로세스 안에서 연결이 한 번 닫힌 뒤 새로 연 연결로 한글 컬럼 조회

## 시도한 것들

1. ❌ NCHAR/NVARCHAR 값 문제로 추정 → 로컬에서 정상, 값이 아니라 컬럼명 문제였음
2. ❌ 앱 서버 화면에서 연결 테스트·세션 강제 종료 후 재현 시도 → 서버 프로세스에서는 재현 안 됨(원인 미확정)
3. ✅ unixODBC 추적: 정상 연결은 UTF-8 바이트를 한 칸씩 넓혀 9칸, 깨진 연결은 제대로 변환한 3글자를 9칸으로 알려 6칸이 NUL·쓰레기
4. ✅ 로케일 비교: `C.UTF-8`은 닫힌 뒤 새 연결부터 깨짐, `C`는 항상 바이트 그대로(복원 가능)

## 원인

드라이버에 W 함수가 없어 unixODBC가 변환을 대신하는데, 바이트 인코딩을 로케일에서 읽고 길이는 바이트 수 그대로 넘긴다. 쓰레기가 NUL이면 CSV 저장에서 `escapechar` 오류, UTF-16으로 해석 불가한 값이면 `utf-16-le` 오류. 이상해진 연결은 `SELECT 1 FROM DUAL` pre-ping을 통과해 풀에 최대 1시간 남아 오류가 반복된다. NLS_USE를 바꾸면 풀을 새로 만들어(evict) 회복된 것처럼 보인다.

## 해결

- 컨테이너 `LC_ALL=C` + `PYTHONUTF8=1` → [[decisions/053-altibase-container-c-locale]]
- 방어: 컬럼명 NUL 이후 잘라내기·원본 경고 로그(`[ALTIBASE] NUL in result column names`), 문자 변환 오류 메시지에 사유와 재시도 방향.

## 교훈

- 증상이 "어느 순간부터"면 연결·프로세스 상태 의존을 먼저 의심하고, "연결 하나 열고 닫은 뒤 새 연결"로 재현한다.
- 같은 이미지라도 별도 프로세스와 서버 프로세스 결과가 다를 수 있다. 재현 결과가 실제 증상과 같은 원인인지는 운영 로그로 확정한다.
- 범용 정리: [[knowledge/troubleshooting/odbc-column-names-byte-widened-mojibake]]
