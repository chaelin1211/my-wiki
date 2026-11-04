---
type: session-log
project: dna-sql-agent
date: 2026-10-19
duration: 
focus: "Altibase 한글 컬럼명 깨짐, 결과 표 컬럼 순서, 후속 질문 링크 보정"
tools-used: [claude-code, docker, colima, chrome]
outcome: success
---

# 2026-10-19 — Altibase 한글 컬럼명·결과 표 컬럼 순서·후속 질문 링크 보정

## 목표

SQL 실행 도구 결과 표에서 한글 컬럼명이 깨지는 문제(요약에는 정상)를 해결하고, 가끔 버튼이 안 되는 후속 질문 링크(`dna-ask`)를 점검한다.

## 수행한 작업

1. 결과 표 컬럼 문제 조사 — 백엔드는 컬럼명을 그대로 보내고 있었고, 대화를 다시 열면 **컬럼 순서**가 바뀌는 것을 확인. 대화 기록(`messages.components`, JSONB)이 행 객체 키를 재정렬하는 것이 원인. 웹이 백엔드가 함께 보내는 `columns` 배열로 순서를 정하도록 수정(결과 표·엑셀 다운로드·엑셀 반영).
2. 테스트용 한글 컬럼 테이블 생성 — `dnasql_agent.public.test_korean_columns`.
3. Altibase 재현 환경 구축 — Docker Hub 공식 이미지는 MAC 주소에 묶인 라이선스가 있어야 기동. support.altibase.com에서 받은 **A+ Edition 서버 설치본**(라이선스 불필요)으로 `~/altibase-aplus/`에 이미지 `altibase-aplus:7.3`을 만들어 `localhost:20300`에 기동. 한글 테이블 `SYS.TEST_KOREAN_COLUMNS` 생성.
4. 백엔드 로컬 Docker 실행 — `Dockerfile.local`에 Altibase 클라이언트 설치가 빠져 있어 추가. 맥 에뮬레이션에서 mariadb 컴파일 중 gcc SIGSEGV → `PIP_CFLAGS=-O0`. 연결 `altibase-aplus-local`(호스트 `host.docker.internal`), 시스템 `altibase-korean-test` 등록.
5. 원인 확정 — 실서버에서 드라이버 원본 컬럼명이 `위치명 → 'ì\x9c\x84ì¹\x98ëª\x85'`(UTF-8 바이트를 1바이트씩 넓힌 형태). 수정 전 이미지(`dna-sql-agent:0.9`)로 화면 깨짐 재현.
6. 컬럼명 복원 — `altibase_odbc.repair_column_name()`이 이 형태만 연결 NLS_USE 문자셋으로 되돌림. SQL 실행 결과와 벡터화 표본 조회 두 곳에 적용. 벡터화에서는 한글 컬럼의 예시 값(`data_example`)이 통째로 빠지던 문제도 함께 해결.
7. `dna-ask` 후속 질문 링크 검토 — 저장된 답변 1,821건 분석(10월 형식 위반 약 1%). 렌더 직전에 `]`와 `(` 사이 공백 제거, 닫히지 않은 괄호 보완, 리스트 기호 추가로 보정.
8. `Dockerfile.local` 공용/개인 분리 — 공용은 Altibase 클라이언트 설치만, 맥 전용 설정(`PIP_CFLAGS`, CPU판 torch)은 `Dockerfile.local.mac`(`.git/info/exclude`)로.
9. 브랜치·PR — 최신 태그에서 `fix/korean-columns`를 따 커밋한 뒤 최신 main으로 리베이스. 백엔드 PR #183(커밋 3개), 웹 PR #105(커밋 2개).

## 핵심 결정

- **후속 질문 링크는 프롬프트를 더 조이지 않고 화면에서 보정** — 이미 저장된 대화에도 적용되고, 프롬프트는 이미 충분히 강함. 질문 앞뒤 `{ }` 제거는 제외.
  → ADR: [[decisions/050-dna-ask-link-render-normalization]]
- **Altibase 컬럼명은 드라이버 설정이 아니라 읽는 지점에서 복원** — 영문은 원래 정상이므로 디코딩 설정(`SQL_WMETADATA`)을 바꾸면 영문이 깨짐. 깨진 형태일 때만 되돌리는 방식이 안전.
- **릴리스 태그 대신 최신 main 기준으로 배포** — 처음엔 `날짜_LH_PoC` 태그에서 분기했다가, 최신 main 배포 승인에 따라 리베이스.

## 배운 것

- PostgreSQL JSONB는 객체 키 순서를 보존하지 않는다 → [[knowledge/troubleshooting/postgres-jsonb-object-key-order]]
- ODBC 드라이버가 비ASCII 컬럼명을 바이트 단위로 넘기면 영문은 멀쩡하고 한글만 깨진다 → [[knowledge/troubleshooting/odbc-column-names-byte-widened-mojibake]]
- Altibase 재현은 Docker Hub 이미지가 아니라 A+ Edition 설치본으로 → [[knowledge/tools/altibase-aplus-docker]]
- 컬럼명에 따옴표를 붙여도 이 깨짐은 해결되지 않음(실서버 확인). 따옴표는 SQL 해석 단계 문제.
- 테스트는 "설정이 있다"가 아니라 "수정 전 소스에서 실패하는지"까지 봐야 의미가 있다.

## 문제 & 해결

- **문제:** Altibase 결과 표 한글 컬럼명 깨짐
- **원인:** ODBC 드라이버가 컬럼명을 UTF-8 바이트 단위로 넓혀 반환
- **해결:** 읽는 지점에서 연결 문자셋으로 복원
  → 이슈: [[issues/altibase-odbc-korean-column-names-byte-widened]]
- **문제:** 다시 연 대화의 결과 표 컬럼 순서가 SQL과 다름
- **원인:** JSONB 키 재정렬
- **해결:** `columns` 배열 기준 표시
  → 이슈: [[issues/result-table-column-order-lost-after-jsonb-reload]]

## 다음 할 일

- [ ] PR #183·#105 리뷰·머지 후 main으로 배포
- [ ] Altibase 시스템 재벡터화(`altibase-LH-sample` 포함) — 한글 컬럼 `data_example` 채우기
- [ ] 테스트 자원 정리 — 테스트 메시지 4건(`conv_aa42dc19`, id 2071315~2071318), 연결 `altibase-aplus-local`, 시스템 `altibase-korean-test`, 테이블 `public.test_korean_columns`, 로컬 컨테이너·이미지
- [ ] `test_connection_pool.py` 기존 실패 20건(`RunSqlToolArgs.title` 필수 반영 안 됨) 정리

## 효과적이었던 프롬프트

```
영문 명은 깨진 적 없어
```
→ 가설(`SQL_WMETADATA`)이 영문까지 깨뜨린다는 모순을 드러내 잘못된 수정을 되돌리게 함.
