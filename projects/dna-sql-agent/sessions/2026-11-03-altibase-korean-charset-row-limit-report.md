---
type: session-log
project: dna-sql-agent
date: 2026-11-03
duration: 2일 (11-03 ~ 11-04)
focus: "Altibase 한글·문자셋 오류, 행 제한 문법, 값 프로파일, 보고서 404"
tools-used: [claude-code, docker, unixodbc-trace, altibase-aplus-7.3]
outcome: success
---

# 2026-11-03 — Altibase 한글·문자셋 오류, 행 제한 문법, 값 프로파일, 보고서 404

## 목표

운영(RICS, Altibase 7.1.0.10.6)에서 보고된 오류의 원인을 확인하고 한 번에 배포할 수 있게 수정한다. 데이터 탐색의 `need to escape`·`utf-16-le`, 마스킹 42S22, 데이터 구조 검색의 `Invalid table identifier`, 값 프로파일 세션 끊김·제외 테이블 스캔, 잦은 `FETCH` 차단, PDF 보고서 404.

## 수행한 작업

1. 로컬 Altibase A+ 7.3(`altibase-aplus`)과 main 이미지 앱 컨테이너를 띄우고, 한글 테이블·컬럼·데이터와 마스킹·NCHAR·CLOB 테스트 테이블을 만들어 재현 환경 구성.
2. `need to escape`·`utf-16-le` 원인 추적: 별도 프로세스에서 "연결이 닫힌 뒤 새 연결"부터 한글 컬럼명 뒤에 NUL·쓰레기가 붙는 것을 재현, unixODBC 추적으로 드라이버에 W 함수가 없어 unixODBC가 변환하며 길이를 바이트 수로 넘기는 것과 프로세스 로케일(`C.UTF-8`)이 변환 방식을 좌우하는 것을 확인 → 컨테이너 `LC_ALL=C` + `PYTHONUTF8=1`.
3. 데이터 구조 검색 도구의 영문 전용 식별자 검사를 유니코드 허용으로 변경.
4. 컬럼명 NUL 정리·경고 로그, 마스킹 `SELECT *` 확장의 한글 컬럼명 복원·따옴표 처리, 문자 변환 오류 메시지 보강, Altibase 오류 메시지 속 한글 복원.
5. 행 제한 문법: DB가 실행 못 하는 문법(Oracle `LIMIT`, Altibase·MySQL·SQLite `FETCH`)을 검증 단계에서 대체 문법 안내와 함께 거절하고, 시스템 프롬프트 DB 메타데이터에 DB별 행 제한 한 줄 추가.
6. 값 프로파일: 제외 비교를 `should_skip_table`로 통일, 재생성 시 제외 테이블 기존 트리플을 5,000행씩 나눠 삭제, COUNT·PK·L4 실패와 연결 끊김 시 테이블명·오류 코드 로그, 이름 컬럼 접미어에 `명`·`명칭`·`이름` 추가.
7. 보고서: 화면이 보낸 답변 첫 행 ID까지만 읽던 것을 그 답변의 끝까지 읽도록 변경, 메시지별 슬라이드는 답변 행 ID 목록으로 비교.
8. `/data-tour` 기본 커맨드 자동 등록.
9. 커밋 14개를 원격 main에 반영(브랜치 추적 설정 실수로 리뷰 없이 반영, 사용자 결정으로 유지).

## 핵심 결정

- **Altibase 한글 문자셋 문제는 코드가 아니라 컨테이너 로케일로 해결:** MS949 우회는 일부 문자 손실, JDBC는 범위 과다 → [[decisions/053-altibase-container-c-locale]]
- **행 제한 문법은 자동 보정하지 않고 대체 문법 안내와 함께 거절 + 프롬프트 한 줄:** 실행 SQL과 LLM 원본 일치, 새 대화마다 반복되는 실수는 프롬프트로 차단 → [[decisions/054-row-limit-reject-with-hint]]
- 보고서는 화면을 고치지 않고 백엔드가 받은 ID를 "그 답변의 끝까지"로 해석. 스트림 종료 ID를 바꾸면 새로 고침 화면과 피드백 ID가 어긋나서 제외.
- 값 프로파일 제외 테이블 정리는 전체 삭제·재삽입이 아니라 제외 대상만 삭제. 일시적 L4 실패로 정상 트리플이 사라지는 위험 회피.

## 배운 것

- Altibase ODBC 7.1 클라이언트는 UTF-16(W) API가 없고, pyodbc는 항상 W 함수를 써서 unixODBC가 변환을 대신한다. unixODBC 2.3.12는 ini로 변환 인코딩을 지정할 수 없고 로케일(`nl_langinfo`)을 본다.
- `LC_ALL=C`여도 `PYTHONUTF8=1`이면 Python 자체의 문자열·파일·출력은 UTF-8을 유지한다. Postgres·SQLite·PDF/PPT/Excel·차트·로그 파일에 부작용 없음.
- KO16KSC5601 접속은 완성형 밖 한글(똠·햏·뷁·샾)을 오류 없이 `?`로 바꾼다. 우회가 필요하면 MS949.
- Altibase·Oracle의 고정 길이 문자 비교는 뒤 공백을 무시한다. 공백이 붙은 코드도 SQL 결과는 같다.
- 값 프로파일은 PK가 있는 작은 코드표만 사전으로 만든다. 접미어가 영문뿐이라 한글 코드표가 전부 빠지고 있었다.
- 로컬 도커는 Apple Silicon에서 amd64 이미지를 에뮬레이션해 임베딩 검색이 1~2초에서 30~50초로 느려진다(운영 x86은 해당 없음으로 추정).

## 문제 & 해결

- **문제:** 데이터 탐색이 가끔 `need to escape, but no escapechar set`·`utf-16-le`로 우다다 실패하고 NLS_USE를 바꾸면 회복.
- **원인:** UTF-8 로케일에서 unixODBC가 한글 컬럼명을 UTF-16으로 변환하며 길이를 바이트 수로 넘김. 이상해진 연결은 pre-ping을 통과해 풀에 최대 1시간 남음.
- **해결:** 컨테이너 `LC_ALL=C` + `PYTHONUTF8=1`, NUL 정리·로그, 오류 메시지 보강.
  → 이슈: [[issues/altibase-utf8-locale-column-name-nul]]
- **문제:** 결과 표가 있는 대화에서 PDF 404, 여러 질문 대화는 마지막 질문 결과 누락.
- **원인:** 한 답변이 여러 행으로 저장되는데 화면은 첫 행 ID를 보내고, 보고서는 그 ID까지만 읽음.
- **해결:** 받은 ID가 속한 답변의 끝까지 읽기, 메시지별 슬라이드는 답변 행 ID 목록으로 비교.
  → 이슈: [[issues/report-reads-only-first-row-of-answer]]

## 다음 할 일

- [ ] 개발 서버 배포 후 지식 베이스 검색 시간(1~2초 복귀 여부)과 RICS `need to escape`·`utf-16-le` 재발 여부 확인 (`[ALTIBASE] NUL in result column names` 로그)
- [ ] RICS 값 프로파일 재생성(`force=true`)으로 제외 테이블 트리플 정리
- [ ] 데이터 탐색 결과에 마스킹 미적용 (보류, 보안)
- [ ] 프롬프트 VALUE MAPPING이 사용자별 차단 테이블을 거르지 않음 (보류, 보안)
- [ ] 테스트 자원 정리: 로컬 `altibase-aplus`·`dna-sql-agent-main`·이미지 `local-main`/`local-fix`, 공유 DB 커넥션 `altibase-aplus-local`·시스템 `altibase-korean-test`, 원격 브랜치 `fix/altibase-korean-identifiers`
- [ ] (참고) 고정 길이 문자형 코드 끝 공백 정리, PK 없는 코드표·뷰 지원, value profile COUNT 5만 건 상한

## 효과적이었던 프롬프트

```
수정은 하지말고 일단 오류 확인부터 하고 싶어 그니까 도커로 알티베이스랑 서버 띄워줘
```
