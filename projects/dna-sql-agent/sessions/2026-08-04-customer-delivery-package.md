---
type: session-log
project: dna-sql-agent
date: 2026-08-04
duration: 종일
focus: "고객사 배포 패키지 구축 — 소스 접근 없이 이미지로 전달"
tools-used: [claude-code, docker, gitleaks]
outcome: success
---

# 2026-08-04 — 고객사 배포 패키지 구축

## 목표

타 사이트(고객사)에 소스 접근 없이 제품을 전달할 수 있는 배포 체계를 만든다.
"도커 이미지 만들어서 주면 되나?"에서 출발했다.

## 수행한 작업

1. **현행 조사** — 이미지에 무엇이 들어가는지 확인
   - `.dockerignore` 에 `.env`·`config/` 가 없어 시크릿이 이미지에 그대로 포함
   - `log/` 99MB, `tmp/`, Chroma 인덱스까지 실려 빌드 컨텍스트 114MB
   - `defaults/database.json`·`qdrant.json` 에 내부 IP `192.168.101.129` 하드코딩

2. **배포 전용 저장소 신설** — `DnA-Platform-Development-Team/dna-sql-agent-deploy` (private)
   - `package.sh` — 빌드 → `docker save` → 병합 → 시크릿 검사 → zip
   - `common/` — `init.sh`, `start.sh`, `INSTALL.txt`, compose, nginx 3종, `.env.template`
   - 산출물: `dist/<사이트>/<버전>/<일시>/` 에 zip · sha256 · 안내.txt

3. **설치 자동화**
   - `init.sh` — 보안 키 생성, 폴더 준비, 이미지 로드, 웹 서버 선택, 관리자 계정 발급
   - `start.sh` — 구성 확인 → 기동 → 준비 대기 → 관리자 계정 생성 → 접속 주소 안내
   - 인증서 없으면 HTTP 설정으로 자동 전환, 기존 웹 서버 사용 시 스니펫 제공

4. **소스 저장소 하드닝**
   - `.dockerignore` 정리 (컨텍스트 114MB → 10.7MB)
   - `docker-entrypoint.sh` 추가 — 마운트 폴더 소유권 처리
   - 웹: `allowedDevOrigins` 를 프로덕션 빌드에서 제외

## 핵심 결정

- **배포 패키지를 별도 저장소로 분리** — 소스 저장소는 고객에게 줄 수 없고,
  배포 패키지는 고객이 열어보는 물건이라 성격이 다르다.
  → ADR: [[projects/dna-sql-agent/decisions/030-deploy-package-separate-repo]]

- **마운트 폴더 소유권을 엔트리포인트에서 처리** — 설치자에게 `chown`·`sudo` 를
  요구하지 않는다. postgres 공식 이미지와 같은 구조.
  → ADR: [[projects/dna-sql-agent/decisions/031-container-mount-ownership-entrypoint]]

- **시크릿은 패키지에 넣지 않는다** — 고객사에서 `init.sh` 가 생성한다.
  `package.sh` 가 압축 직전에 검사해 값이 있으면 빌드를 중단한다.

- **`DB_MODE`/`VECTOR_MODE` 구분값 도입** — 호스트명이 `postgres` 인지로
  내장·외부를 추측하던 것을 명시적 스위치로 바꿨다.

## 배운 것

- **바인드 마운트는 이미지의 권한 설정을 무력화한다.** `chmod 777 -R $HOME` 이
  있어도 마운트하면 호스트 폴더로 대체되어 소용없다.
- **`uid 1005` 는 우리 개발 서버 `dnadev` 계정 번호**였다. 사내에서는 우연히
  일치해 문제가 드러나지 않았고, 고객사에서 처음 터질 값이었다.
- **`.env` 는 최초 기동 시 `config/*.json` 을 만드는 시드**일 뿐이다. 이후에는
  JSON 이 진짜라 `.env` 를 고쳐도 반영되지 않는다.
- **질의응답 LLM 은 `.env` 가 아니라 `llm_connections` 테이블에서 온다.**
  `.env` 의 `LLM_*` 는 PPT 보고서 생성 전용이다.
- **관리자 부트스트랩 경로가 없다.** 가입하면 무조건 일반 그룹이라, DB 를 직접
  고치지 않으면 아무도 관리자가 될 수 없다.

## 문제 & 해결

- **문제:** `.dockerignore` 에 `.env` 를 넣자 사내 CI 배포가 전부 크래시
  (`KeyError: 'DB_ENCRYPTION_KEY'`)
- **원인:** CI 배포는 `.env` 를 마운트하지 않고 **이미지에 구워진 파일**을 읽고
  있었다. `config/`·`log/` 만 보고 "런타임 영향 없음"으로 판단한 것이 오판.
- **해결:** 워크플로가 체크아웃한 `.env` 를 `/home/dnadev/.env` 로 복사하고
  마운트하도록 수정. 서버에는 즉시 배치해 복구.
  → 로그: [[projects/dna-sql-agent/issues/log]]

- **문제:** 외부 DB 를 지정했는데 인증 실패
- **원인:** `init.sh` 가 외부 DB 여부와 무관하게 `DNASQL_AGENT_DB_PASSWORD` 를
  랜덤 생성. 기존 서버 비밀번호와 맞을 리가 없다.
- **해결:** `DB_MODE=external` 이면 생성하지 않고 필수 입력 항목으로 안내.

## 다음 할 일

- [ ] `qdrant`·`database` 설정을 `.env` 직독으로 변경 (설정 화면에서 다루지 않음 확인)
      → `defaults/*.json` 내부 IP 삭제, `migrations.py` 해당 마이그레이션 제거,
        `SECTIONS` 제외 시 설정 API 의 DB 비밀번호 평문 노출도 함께 해결
- [ ] 임베딩 모델을 이미지에 번들링 (폐쇄망이면 기동 불가)
- [ ] Qdrant 서버 버전을 클라이언트(1.17)에 맞추기
- [ ] CPU 전용 torch 로 이미지 축소 (16.3GB → 6~7GB 예상)
- [ ] 관리자 부트스트랩·LLM 미설정 분기를 백엔드에서 처리
- [ ] dev 워크플로 체크아웃 브랜치를 `main` 으로 복구
- [ ] `upgrade.sh`, `pigz` 병렬 압축, `pv` 진행률

## 효과적이었던 프롬프트

```
"근거"
"보편적인 방법 맞아???"
```

주장에 근거를 요구하니 실제로 확인하게 되었고, 그 과정에서 "postgres·nginx
공식 이미지와 같은 방식"이라는 설명이 부정확함을 발견했다(nginx 는 앱 자체
권한 분리라 메커니즘이 다름). 근거 요구가 잘못된 일반화를 걸러냈다.
