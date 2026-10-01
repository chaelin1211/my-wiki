---
type: project-overview
project: dna-sql-agent-deploy
created: 2026-08-18
updated: 2026-08-26
status: active
stack: [bash, docker, docker-compose, github-actions, nginx, postgres, qdrant]
repo: "DnA-Platform-Development-Team/dna-sql-agent-deploy"
goal: "고객사(주로 폐쇄망)에 전달할 설치 패키지를 만들고, 고객이 스스로 설치·기동할 수 있게 한다"
---

# dna-sql-agent-deploy

## 목표

> [[projects/dna-sql-agent/overview|dna-sql-agent]] 와 [[projects/dna-sql-agent-web/overview|dna-sql-agent-web]] 을 고객사에 납품 가능한 형태로 묶는 저장소.
> 이미지·설정·설치 스크립트를 하나의 zip 으로 만들고, 고객은 압축을 풀어
> `init.sh` → `start.sh` 두 단계로 설치한다. 인터넷이 없는 폐쇄망을 전제로 한다.

## 구성

| 경로 | 역할 |
|------|------|
| `package.sh` | 패키지 빌더. 이미지 save → 시크릿 검사 → zip |
| `common/` | 고객에게 나가는 내용물 (compose, 스크립트, 설정, 안내문) |
| `sites/<이름>/` | 사이트별 오버레이 (`env.overlay`, `config/*.json`) |
| `.packagerc` | 빌드 환경 (원격 도커 주소, 소스 경로) — 커밋하지 않음 |
| `.github/workflows/package.yml` | self-hosted 러너에서 패키지 생성 |

## 고객 설치 흐름

```
zip 전달 → unzip → init.sh → start.sh → 관리자 화면에서 LLM 연결 등록
```

- `init.sh` — 보안 키 생성, 폴더 준비, 이미지 로드, 웹 서버 구성 선택, 관리자 계정 발급
- `start.sh` — 라이선스 확인 → 컨테이너 기동 → 준비 대기(로그 출력) → 관리자 계정 생성

## 컨테이너 구성

| 서비스 | 비고 |
|--------|------|
| backend | `dna-sql-agent` |
| web | `dna-sql-agent-web` |
| postgres | 대화 이력·계정. 외부 DB 로 대체 가능 (`DB_MODE=external`) |
| qdrant | 벡터 검색. 외부 서버로 대체 가능 (`VECTOR_MODE=external`) |
| nginx | 제공 웹 서버. 기존 웹 서버를 쓰면 프로필에서 제외 |

프로필(`COMPOSE_PROFILES`)로 bundled 여부를 정하며, `init.sh` 가 `.env` 값을 보고 채운다.

## 컨테이너 밖에 두는 것

이미지를 가볍게 유지하고 버전 교체 시 살아남게 하려고 호스트에서 마운트한다.
위치는 모두 `.env` 로 옮길 수 있다.

| `.env` | 컨테이너 경로 | 내용 |
|--------|--------------|------|
| `DATA_DIR` | (postgres/qdrant 볼륨) | 대화 이력·벡터 데이터 |
| `LOG_DIR` | `/data/apps/dna_sql_agent/log` | 로그 |
| `MODEL_DIR` | `/data/apps/dna_sql_agent/models` | 임베딩 모델 (약 2GB) |
| `LICENSE_DIR` | `/data/apps/dna_sql_agent/license_files` | 라이선스 키 |
| — | `/data/apps/dna_sql_agent/hf_cache` | 허깅페이스 캐시(`HF_HOME`). 폴더는 항상 만들어지고, 모델을 내려받는 구성에서만 채워진다 |

## 관련 결정

- [[001-offline-embedding-model]] — 폐쇄망에서 임베딩 모델을 어떻게 공급할 것인가

## 알려진 이슈

- [[issues/embedding-model-not-found-despite-correct-mount|마운트·파일 다 정상인데 임베딩 모델 미탐지]] (미해결)

## 세션 기록

- [[sessions/2026-08-18-offline-package-and-deploy-hardening]]
- [[sessions/2026-08-26-embedding-model-not-found-diagnosis]]

## 관련 프로젝트

- [[projects/dna-sql-agent/overview|dna-sql-agent]] — 백엔드. 라이선스·임베딩 로직이 여기 있다
- [[projects/dna-sql-agent-web/overview|dna-sql-agent-web]] — 프론트엔드
