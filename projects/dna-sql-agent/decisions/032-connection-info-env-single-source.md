---
type: decision-record
project: dna-sql-agent
date: 2026-08-05
status: accepted
superseded-by: ""
tags: [configuration, deployment, security]
---

# ADR-032: 접속정보의 출처를 `.env` 하나로 고정

## 맥락

설정이 두 층으로 나뉘어 있었다. `.env` 가 최초 기동 시 `config/*.json` 을 만들고,
그 뒤로는 JSON 이 진실이 된다. 관리자 화면에서 바꾸는 운영 설정에는 맞는 구조다.

문제는 **접속정보까지 그 경로를 탔다**는 것이다. 고객사 배포 리허설에서 이렇게
드러났다.

- `.env` 의 DB 비밀번호를 고쳤는데 기동이 `asyncpg InvalidPasswordError` 로 실패
- 앱은 첫 기동 때 만들어진 `config/database.json` 의 옛 값을 읽고 있었다
- Qdrant 도 같은 이유로 닫힌 포트를 물고 있었다

설치 도중 접속정보를 바로잡는 것은 흔한 일인데, 그게 반영되지 않는다.

부가 문제도 있었다.

- `SECTIONS` 에 `database`·`qdrant`·`llm` 이 있어 `GET /api/v1/settings/{id}` 로
  DB 비밀번호와 api_key 가 **평문으로** 나갔다
- `defaults/database.json` 이 값 없을 때 사내 IP `192.168.101.129` 와
  `postgres`/`postgres` 로 조용히 폴백했다. 고객사에서는 엉뚱한 곳에 붙거나
  인증 실패로 끝나는데 원인이 드러나지 않는다

## 선택지

### 옵션 A: 현행 유지 + 설치 절차로 보완
- **장점:** 코드 변경 없음
- **단점:** "설치 중 값을 고치면 `config/` 도 지우라"는 절차를 사람이 기억해야 한다.
  평문 노출은 그대로
- **비용/노력:** 없음

### 옵션 B: `config/*.json` 을 매 기동 시 `.env` 로 덮어쓰기
- **장점:** 기존 구조를 크게 안 바꿈
- **단점:** 같은 값이 두 곳에 남는다. 관리자 화면에서 바꾼 값이 재기동 때 되돌아가
  "화면에서 바꿨는데 안 먹는다"가 된다
- **비용/노력:** 낮음

### 옵션 C: 접속정보를 `config` 에서 빼고 `.env` 직독
- **장점:** 출처가 하나. 고치고 재기동하면 반영된다. 설정 API 노출 경로가 사라진다
- **단점:** 설정이 두 종류(파일/환경변수)로 나뉘어 "어디서 고치나"를 문서로
  안내해야 한다
- **비용/노력:** 중간 — 소비처 8곳 전환, 테스트, 기존 설치본 정리

## 결정

**옵션 C** — 접속정보는 `dna/settings/env_config.py` 가 환경변수에서 직접 읽는다.

배치 기준을 이렇게 고정한다.

| 성격 | 위치 | 이유 |
|---|---|---|
| 관리자 화면에서 조정하는 운영 설정 | `config/*.json` | 재기동 없이 바꾸고 이력이 파일에 남는다 |
| 사이트마다 다른 접속정보·비밀 | `.env` (직독) | 설치자가 채우는 값이고 설정 API 로 새면 안 된다 |
| 제품이 정하는 값 | `defaults/*.json` | 사이트가 건드릴 값이 아니다 |

대상: `DNASQL_AGENT_DB_*`, `QDRANT_*`, 보고서용 `LLM_*`, `LANGFUSE_*`.

## 근거

- **고칠 수 있어야 한다.** 접속정보는 설치·이전·장애 대응 중에 바뀐다. 한 번 굳는
  구조는 그 상황에 맞지 않는다
- **화면에서 다루지 않는다.** 이 값들은 관리자 화면에 없다. `config` 에 둘 이유가
  애초에 약했다
- **기본값을 코드에 두지 않는다.** 비면 기동을 멈추고 어느 항목이 비었는지 알린다.
  잘못된 대상에 조용히 접속해 한참 뒤에 드러나는 것보다 낫다
- **자격증명은 저장하지 않는다.** Langfuse 는 SDK 가 환경변수를 직접 읽어 저장해도
  쓰이지 않았다. `secret_key` 가 평문으로 디스크에 남기만 했다

## 결과

- 기존 설치본의 `config/database.json`·`qdrant.json`·`llm.json` 은 기동 시
  `_remove_retired_configs()` 가 삭제한다. 평문 자격증명을 방치하지 않기 위함
- `QDRANT_API_KEY` 는 빈 값이 "인증 없음"이라는 유효한 값이라 필수로 두지 않는다
- 보고서용 LLM 은 보고서를 쓰지 않는 설치도 있어 기동을 막지 않는다.
  실제로 보고서를 만들 때 확인하고 `503` 으로 안내한다
- DSN 조립 시 계정·비밀번호를 URL 인코딩한다. `@ : /` 가 들어가면 깨지던 문제
- 설정이 두 종류로 나뉘므로 문서가 필요하다 → `docs/configuration-reference.md`

향후 재검토: 관리자 화면에서 접속정보를 바꾸는 기능이 생기면 다시 봐야 한다.
그때는 DB 에 저장하는 쪽(`llm_connections` 처럼)이 맞을 것이다.

## 참고 자료

- 세션: [[projects/dna-sql-agent/sessions/2026-08-05-config-source-unification-and-package-workflow]]
- [[projects/dna-sql-agent/decisions/030-deploy-package-separate-repo]]
- `docs/configuration-reference.md`
