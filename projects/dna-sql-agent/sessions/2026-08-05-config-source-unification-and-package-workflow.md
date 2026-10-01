---
type: session-log
project: dna-sql-agent
date: 2026-08-05
duration: 종일
focus: "설정 출처 일원화 + 배포 패키지 워크플로 구축"
tools-used: [claude-code, docker, github-actions, gitleaks]
outcome: success
---

# 2026-08-05 — 설정 출처 일원화와 배포 패키지 워크플로

## 목표

전날 만든 배포 패키지를 로컬에서 리허설하다 기동이 막힌 것을 풀고, 그 원인이던
"같은 값이 두 곳에 있는" 구조를 정리한다. 이어서 패키지 생성을 사람 손이 아닌
워크플로로 옮긴다.

## 수행한 작업

### 1. 기동 실패 추적 — 설정이 두 곳에 있던 문제

`start.sh` 로 띄운 컨테이너가 `asyncpg InvalidPasswordError` 로 죽었다.
`.env` 는 맞는데 앱이 첫 기동 때 만들어진 `config/database.json` 의 옛 비밀번호를
읽고 있었다. Qdrant 도 같은 이유로 닫힌 포트(`192.168.101.12:6333`)를 물고 있었다.

`.env` 는 최초 기동 시 `config/*.json` 을 만드는 씨앗일 뿐이라, 설치 도중
값을 바로잡아도 반영되지 않는 구조가 원인이었다.

### 2. 접속정보를 `.env` 직독으로

- `dna/settings/env_config.py` 신설 — DB·Qdrant·보고서 LLM 을 매 기동 시 환경변수에서 읽음
- 기본값을 코드에 두지 않음. 비면 기동을 멈추고 어느 항목이 비었는지 알림
  (예전 `defaults/database.json` 은 사내 IP `192.168.101.129` 로 조용히 폴백)
- `SECTIONS` 에서 `database`·`qdrant`·`llm` 제외 → 설정 API 의 평문 노출 해소
- DSN 조립에 `quote()` — 비밀번호에 `@ : /` 가 있으면 깨지던 문제

### 3. 설정 초기값 출처를 기본값 하나로

- `rag`·`embedding` — `.env` 덮어쓰기 제거. `_migrate_embedding` 은 `.env` 가 비면
  `model: ""` 을 저장해 모델을 못 여는 버그가 있었음
- `masking` — 레거시 `masking_rules.json` 폐기. `defaults/masking.json` 과 규칙은
  같은데 `default_group_action` 만 달랐다(`none` vs `mask`)
- `observability` — 자격증명을 설정 파일에서 제거(평문 `secret_key` 저장됨).
  켜짐 판정을 `dna/observability/enablement.py` 로 일원화
- `.env` 에서 더 이상 읽지 않는 12줄 제거

### 4. 보고서 API

- 보고서용 LLM 을 `.env` 직독으로. 질의응답 LLM(`llm_connections` 테이블)과 완전 분리.
  `config/llm.json` 을 읽던 곳은 `ppt_slide_service.py` 한 곳뿐이었다
- 예외 원문이 클라이언트로 나가던 것 일반화. DSN 이 그대로 응답에 실릴 수 있었다
  (`0ede9b1` 이 대화 API 에 적용한 것과 같은 조치)

### 5. 배포 스크립트

- `init.sh` 가 외부 DB 사용 시 `DB_ENCRYPTION_KEY` 를 새로 만들지 않도록 수정
- `start.sh` 가 복호화 실패를 성공으로 안내하지 않도록 검사 추가
- 같은 태그 이미지로 로드를 건너뛸 때 교체 절차를 안내 (조용히 넘어가던 것)
- 산출물 경로 단순화 — 버전 폴더 제거, 이름 하나에 사이트·버전·일시를 담음
  `dist/<사이트>/dadap_<사이트>_<버전>_<yyyyMMddHHmmss>/`
- `DIST_DIR`·`MIN_FREE_GB` 추가. 여유 공간 부족 시 **빌드 전에** 중단
- `pigz` 지원 — 있으면 병렬 압축, 없으면 `gzip` 폴백

### 6. 배포 패키지 생성 워크플로 (신규)

`dna-sql-agent-deploy/.github/workflows/package.yml`

- 빌드 서버의 러너에서 실행. 산출물은 그 서버(`/DATA/dadap-packages`)에 남김
- 기본은 **빌드하지 않고** 서버의 `latest` 이미지를 묶음
- 입력: `version` / `site` / `rebuild` / `source_ref`
- `rebuild` 를 켤 때만 소스 저장소 2개를 체크아웃 (`if:` 조건)
- 도구·권한·이미지 확인을 앞단에 배치 — 수 분 뒤에 실패하지 않도록

### 7. 문서

- `docs/configuration-reference.md` 신설 — `.env` 와 `config/*.json` 의 정본
- 폐기된 `llm.json`·`masking_rules.json` 참조를 전 문서에서 제거
- `INSTALL.txt` 에서 운영·문제 해결을 `README.txt` 로 분리 (사용자 작업)

## 핵심 결정

- **접속정보는 `.env` 를 유일한 출처로 삼는다** — `config` 로 굳으면 재기동해도
  반영되지 않고, 설정 API 로 평문이 나간다
  → ADR: [[projects/dna-sql-agent/decisions/032-connection-info-env-single-source]]

- **마스킹 기본 동작을 `mask`(fail-closed)로 통일** — 전략에 없는 그룹이
  개인정보 원본을 보던 상태였다. 정의가 세 곳(defaults·레거시·스키마)이었다

- **패키지 생성에 버저닝을 도입하지 않는다** — 기존 배포 방식에 버저닝이 없다.
  워크플로의 `version` 은 패키지 파일 이름에 붙는 라벨이며, 이미지 태그 체계가
  아니다. `package.sh` 가 버전 태그를 찾으므로 묶기 직전에만 태그를 붙인다

- **산출물을 GitHub 아티팩트로 올리지 않는다** — 한 벌이 4GB 이상이라 왕복
  전송이 낭비고, 전달도 빌드 서버에서 한다

- **오래된 산출물을 자동 삭제하지 않는다** — 전달한 zip 이 곧 "무엇을 보냈는가"의
  기록이고, 같은 버전을 다시 빌드해도 베이스 이미지가 갱신되어 바이트가 같지 않다.
  공간이 부족하면 목록을 보여 주고 중단만 한다

## 배운 것

- **`NEXT_PUBLIC_*` 는 빌드 시점에 JS 번들로 박힌다.** 이미지 안의 `.env.production`
  파일은 런타임에 읽히지 않아, 마운트하거나 컨테이너 환경변수를 줘도 효과가 없다.
  실측으로 확인함 (`docker exec -e ...` 후 번들 검색 → 반영 안 됨)
- **`docker save` 는 이미지가 데몬에 있기만 하면 된다.** 배포(컨테이너 실행)와 무관하다.
  지금 구조에서 "배포해야 save 된다"고 보이는 것은 이미지를 만드는 유일한 경로가
  배포 워크플로이기 때문
- **`actions/checkout` 은 워크스페이스를 매 실행 청소한다.** 산출물을 체크아웃 폴더
  안에 두면 다음 실행 때 사라진다
- **`du -h` 는 진행 표시에 부적절하다.** 1MB 미만을 `0` 으로 찍어 멈춘 것처럼 보인다
- **초반 속도로 외삽하면 안 된다.** `docker save` 초반 4분이 느려 "5.7시간" 으로
  추정했는데, 실제로는 정상 속도로 붙어 15분 안에 끝났다

## 문제 & 해결

- **문제:** 새 이미지를 빌드해 배포했는데 로컬에서 `qdrant.json`·`database.json` 이 다시 생김
- **원인:** `init.sh` 가 **태그만 보고** 이미지 로드를 건너뛴다. 로컬에 `dna-sql-agent:1.0`
  (8/3자)이 남아 있어 8/5에 만든 새 tar 를 무시했고, 옛 코드가 돌았다
- **해결:** 건너뛸 때 조용히 넘어가지 않고 교체 절차를 안내하도록 수정.
  근본 수정(이미지 ID 비교)은 업그레이드 작업 때 함께 하기로 함
  → 이슈: [[projects/dna-sql-agent/issues/same-tag-image-load-skipped]]

- **문제:** `.env` 에 `DB_ENCRYPTION_KEY` 가 있는데 `init.sh` 가 "직접 입력하라"고 안내
- **원인:** 같은 키가 **두 줄** 있었고 앞줄이 빈 값이었다. `grep ... | head -1` 이
  빈 값을 집었다
- **해결:** 중복 줄 제거. 이후 `Fernet key must be 32 url-safe base64-encoded bytes`
  오류까지 함께 사라짐

- **문제:** 화면에서 API 요청이 404
- **원인:** `http://localhost:3000`(웹 컨테이너)으로 직접 접속. 번들은 상대 경로로
  요청하므로 nginx(80)를 거쳐야 백엔드로 간다
- **해결:** nginx 경유 접속. 이후 웹 컨테이너의 호스트 포트를 닫아 우회 자체를 차단(`963a625`)

## 다음 할 일

- [ ] `chore/deploy-hardening` PR 생성 → main 머지
- [ ] 서버 `latest` 이미지가 커진 원인 확인 — 로컬 tar 3.8GiB vs 서버 6.6GB+
      (`docker history dna-sql-agent:latest` 로 큰 레이어 확인)
- [ ] CPU 전용 torch 로 이미지 축소 (`requirements.txt` 의 `cu118` → cpu)
- [ ] 임베딩 모델 이미지 번들링 (폐쇄망 대비, 2.1GB)
- [ ] 빌드 서버에 `pigz` 설치 — gzip 이 코어 하나만 쓰는 것 확인함
- [ ] 스키마 기본값 ↔ `defaults/*.json` 불일치 정리 (status.md 분석 참고)
- [ ] 웹 저장소 `chore/deploy-hardening` 브랜치 push (원격에 없음)

## 효과적이었던 프롬프트

```
"확실해? 그렇게 고치는게 정말 낫다고 생각해?"
"site 값이 왜 필요해"
"기존 배포 방식에 버저닝이 없으니까 우린 뺀거다? 알겠지?"
```

성급한 제안을 되돌리게 한 질문들이다. "무조건 `docker load`" 는 4GB 를 매번
gunzip 하는 비용을 놓친 제안이었고, 워크플로 입력도 과하게 넣었다가 걷어냈다.
결정의 근거를 다시 묻는 것이 잘못된 방향을 일찍 잘랐다.
