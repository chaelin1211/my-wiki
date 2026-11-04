---
type: decision-record
project: dna-sql-agent
date: 2026-11-03
status: accepted
superseded-by: ""
tags: [altibase, odbc, unixodbc, locale, encoding]
---

# ADR-053: Altibase 한글 컬럼명 깨짐은 컨테이너 로케일을 C로 고정해 해결

## 맥락

운영 RICS(Altibase 7.1.0.10.6, DB·접속 문자셋 UTF8)에서 데이터 탐색이 어느 순간부터 `need to escape, but no escapechar set`·`utf-16-le` 오류를 연달아 내고, 커넥션 NLS_USE를 바꾸면 회복되었다. 로컬 재현과 unixODBC 추적으로 다음을 확인했다.

- Altibase ODBC 클라이언트 7.1.0.9.9는 `SQLDescribeCol`만 있고 W(UTF-16) 함수가 없다. pyodbc는 항상 W 함수를 써서 unixODBC 2.3.12가 변환을 대신한다.
- unixODBC는 바이트 인코딩을 프로세스 로케일에서 읽는다. `C.UTF-8`이면 연결이 한 번 닫힌 뒤 새로 연 연결부터 UTF-8 → UTF-16 변환을 하면서 길이를 바이트 수로 넘겨, 한글 컬럼명 뒤에 NUL·쓰레기가 붙는다. `C`이면 항상 바이트를 그대로 넓혀 넘겨 길이가 맞고, 기존 복원 코드(#183)로 한글이 정확히 돌아온다.
- unixODBC 2.3.12에는 변환 인코딩을 ini로 지정하는 설정이 없다.

## 선택지

### 옵션 A: 컨테이너 로케일 `LC_ALL=C` + `PYTHONUTF8=1`
- **장점:** 원인(변환 방식 전환) 자체를 차단. 데이터 손실 없음(완성형 밖 한글·한자·기호·이모지 정상). 코드 수정 없이 Dockerfile 두 줄. 사내 배포·고객 설치 패키지 모두 같은 Dockerfile로 빌드돼 자동 반영.
- **단점:** 프로세스 전체 설정이라 C 라이브러리 동작이 바뀔 수 있음. 점검 결과 Postgres·SQLite·PDF/PPT/Excel·차트·로그 파일 부작용 없음.
- **비용/노력:** 작음.

### 옵션 B: 커넥션 NLS_USE를 MS949(또는 KSC5601)로 운영
- **장점:** 코드·이미지 변경 없음.
- **단점:** DB(UTF8)의 MS949 밖 문자가 오류 없이 `?`로 바뀜. KSC5601은 완성형 밖 한글(똠·햏 등)까지 손실.
- **비용/노력:** 없음, 대신 조용한 데이터 손실 위험.

### 옵션 C: JDBC로 접속 계층 교체
- **장점:** unixODBC 변환 단계 자체가 없어짐.
- **단점:** JVM·JPype·JayDeBeApi 도입, 접속·풀·오류 정제·추출기·마스킹·값 프로파일 재작성, 스레드·성능 위험.
- **비용/노력:** 큼(며칠 이상).

### 옵션 D: 코드에서 증상만 방어
- **장점:** 환경 변경 없음.
- **단점:** NUL은 잘라낼 수 있지만 `utf-16-le`는 드라이버가 이름을 넘기는 단계의 예외라 막을 수 없음.

## 결정

옵션 A. 옵션 D의 방어(NUL 잘라내기·원본 경고 로그, 문자 변환 오류 메시지 보강)는 고객 환경에서 로케일이 덮어써지는 경우에 대비해 함께 유지한다.

## 결과

- `Dockerfile`·`Dockerfile.local`의 런타임 환경변수에 `ENV LC_ALL=C`, `ENV PYTHONUTF8=1`.
- 배포 워크플로·`dna-sql-agent-deploy` 수정 불필요. 고객 `.env`에 `LC_ALL`을 직접 넣는 경우만 덮어써짐.
- 로케일이 C로 고정되면서 Altibase 오류 메시지 속 한글도 항상 바이트 형태로 와서 확정적으로 복원 가능해짐.
- 근본 해결(W 함수 제공 클라이언트)은 Altibase 기술지원 문의 대상.
