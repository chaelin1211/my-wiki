---
type: knowledge
tags: [altibase, docker, database, license, testing]
created: 2026-10-19
updated: 2026-10-19
---

# Altibase를 로컬 Docker로 띄우기 — A+ Edition

## 핵심

**Docker Hub 공식 이미지(`altibase/altibase`)는 라이선스 없이는 기동하지 않는다.** 개발·테스트용이면 라이선스가 필요 없는 **A+ Edition 서버 설치본**으로 직접 이미지를 만든다.

## Docker Hub 이미지의 함정

- 태그 8.1·7.3·7.1 모두 **amd64 전용** → Apple Silicon은 `--platform linux/amd64`(에뮬레이션)
- 시작 스크립트가 `$ALTIBASE_HOME/conf/license` 파일이 없으면 메시지 3줄만 찍고 종료
- 빈 파일로 우회해도 서버가 기동 시 `Check License → No valid license present!`로 실패 — 이미지 서버는 A+가 아님
- 트라이얼 라이선스는 **MAC 주소에 묶임** → 컨테이너는 `--mac-address`를 고정해야 함
- 기본 DB 문자셋이 `KO16KSC5601`(UTF8 아님)
- support.altibase.com에는 셀프 라이선스 발급 메뉴가 없고, 기술지원 요청은 계약 SID 필요

## A+ Edition으로 만들기

1. support.altibase.com 로그인 → 다운로드에서 `altibase-server-7.3.x-A+_Edition-LINUX-X86-64bit-release.run` 받기 (로그아웃 상태에선 서버가 목록에 안 보이기도 함)
2. 설치 프로그램이 무인 설치를 지원한다. 문자셋·아카이브 옵션은 필수.
   ```bash
   ./altibase-server-…-A+_Edition-….run --mode unattended \
     --prefix /home/altibase/altibase-server --select_install_type fullpkg \
     --createdb_option no --archivelog_values noarchivelog \
     --db_char_set UTF8 --national_char_set UTF16 --mem_max_db_size 1G
   ```
   `--createdb_option yes`는 컨테이너 안에서 DB 생성이 조용히 실패해서, DB는 첫 기동 때 따로 만든다.
3. 첫 기동 스크립트(일반 사용자 `altibase`로 실행)
   ```bash
   . $ALTIBASE_HOME/conf/altibase_user.env
   isql -u sys -p MANAGER -sysdba -noprompt <<EOF
   startup process;
   CREATE DATABASE mydb INITSIZE=10M NOARCHIVELOG CHARACTER SET UTF8 NATIONAL CHARACTER SET UTF16;
   shutdown abort;
   EOF
   isql -u sys -p MANAGER -sysdba -noprompt <<< "startup service;"
   ```
   DB 이름은 `altibase.properties`의 `DB_NAME`(기본 `mydb`)과 같아야 한다. 부트 로그에 `Server is Altibase A+ Edition.`이 찍히면 성공.
4. 접속: `localhost:20300`, `sys` / `manager`. 다른 컨테이너(백엔드)에서는 호스트를 `host.docker.internal`로.

## 클라이언트(ODBC 드라이버)

- 클라이언트 `.run`도 **리눅스 x86-64 전용**이라 맥 네이티브 파이썬에서는 접속 불가 → 백엔드도 amd64 컨테이너로 띄워야 함
- 드라이버 매니저(unixODBC)에 `[Altibase]`로 등록하고, `libodbcinst.so` 심링크가 있어야 접속됨

## 관련 페이지

- [[knowledge/tools/colima]] — amd64 에뮬레이션 빌드 문제
- [[knowledge/troubleshooting/odbc-column-names-byte-widened-mojibake]]
- 사례: [[projects/dna-sql-agent/issues/altibase-odbc-korean-column-names-byte-widened]]
