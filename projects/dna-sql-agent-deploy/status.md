---
type: project-status
project: dna-sql-agent-deploy
created: 2026-08-18
updated: 2026-08-28
phase: active
---

# dna-sql-agent-deploy — 현재 상태

## 현재 단계

📦 **폐쇄망 납품 대응** — 2026-08-28 고객사 서버에서 **기동까지 성공**했다.
임베딩 모델 미탐지는 원인 확정·해소됐고(모델 파일 `700` + `:ro` 마운트),
남은 것은 그 재발 방지를 패키지에 반영하는 일과 라이선스 정책 확정이다.
고객사 서버가 **rootless Docker + vfs** 라는 점이 이 현장의 상수다.

## 완료된 것

- [x] 패키지 빌더 (`package.sh`) — 이미지 save, 시크릿 검사, zip, sha256, 안내문
- [x] 사이트별 오버레이 (`sites/<이름>/env.overlay`, `config/*.json`)
- [x] 설치 스크립트 2단계 (`init.sh` → `start.sh`)
- [x] 폐쇄망 임베딩 모델 — [[001-offline-embedding-model]]
- [x] `--with-models` 로 모델 동봉, 모델 캐시 재사용 (`MODEL_CACHE_DIR`)
- [x] 모델·라이선스·로그·데이터를 컨테이너 밖으로 분리, 위치를 `.env` 로 지정
- [x] 라이선스 판정용 호스트 식별자 마운트 (`/etc/machine-id`, `/proc/cpuinfo`, `/proc/meminfo`)
- [x] `start.sh` 기동 실패 진단 — 라이선스 사전 확인, 대기 중 로그 출력, 크래시 루프 즉시 중단
- [x] 서버에서 열리는 포트를 `.env` 로 변경 가능 (`HTTP_PORT` 등)
- [x] 원격 압축 시 pigz 검사를 원격에서 수행
- [x] ADMIN_PORT → INTERNAL_HTTP_PORT 로 이름 정리 + 용도·위험 설명 추가
- [x] 빌드 정의 파일(Dockerfile 등)을 이미지에서 제외
- [x] `package.yml` 워크플로 이름 정리 — `Build Installation Package (Mobigen)`
- [x] **고객사 임베딩 모델 미탐지 원인 확정·해소** (2026-08-28)
      모델 파일이 `700` 으로 반입 + `models` 만 `:ro` 라 chown 자가치유 제외
      → [[embedding-model-not-found-despite-correct-mount]]
- [x] 고객사 폐쇄망 서버 기동 성공 — 이미지 적재, `dnasql_agent` DB 생성, 관리자 로그인

## 진행 중 / 남은 것

- [ ] **라이선스 정책 확정** — 아래 "열린 질문" 참고. 이게 정해져야 폐쇄망 설치가 끝까지 통과한다
- [ ] Qdrant 버전 정리 — 클라이언트 `1.17.0` vs 서버 `v1.12.4` 불일치 경고
- [ ] **`package.sh` 에 `chmod -R a+rX "$MODEL_STAGE"` 추가** — 재발 방지의 정본.
      런타임 조치는 고객사 계정이 `chmod` 를 못 하는 환경에서 무너진다
- [ ] `init.sh` 에 모델 폴더 권한 보정(`chmod -R a+rX`) + **실행 계정 기준** 검증 추가
      (현재 `compgen -G` 검사는 설치 계정 기준이라 권한 문제를 통과시킨다).
      실패해도 진행되게 하고 경고만 남긴다 — 보조 수단
- [ ] **고객사 방화벽 30010/30011 개방 요청** — 서버 기동은 됐으나 외부 접속 미확인
- [ ] **`fuse-overlayfs` 전환 재논의** — 고객사 담당자가 "일단 유지" 결정.
      서버에 이미 설치돼 있고 rootless 라 사용자가 직접 바꿀 수 있다.
      다음 배포 전에 꺼내면 적재 시간이 수 시간 → 수 분이 된다
- [ ] `resolve_model_path()` 가 "없음" 과 "못 읽음" 을 구분해 로깅
- [ ] 폐쇄망 사이트 `.env` 에 `HF_HUB_OFFLINE=1` 배선 (무한 재시작 대신 즉시 실패)
- [ ] 리눅스 장비에서 폐쇄망 전 과정 검증

## 세션 기록

- [[2026-08-18-offline-package-and-deploy-hardening]]
- [[2026-08-26-embedding-model-not-found-diagnosis]]
- [[2026-08-28-rootless-docker-vfs-closed-network-deploy]]

## 열린 질문

**라이선스 시크릿 전달**
`DNA_LICENSE_SECRET` 은 HMAC 대칭키라 검증자 = 발급자다. 고객이 가지면 위조가 가능하다.
`src/dna/license/embedded_secret.py` 로 소스에 굽고 Nuitka 로 컴파일하는 구조가 이미 있으나,
생성 스크립트(`materialize_license_secret.py`)가 CI 에 연결돼 있지 않고 값이 커밋된 상태다.
근본 해결은 비대칭 서명(개인키는 우리가 보관, 공개키만 이미지에)이다.

**키 교체가 반영되지 않는 문제**
이미 활성화된 상태에서는 키 파일을 바꿔도 다시 읽지 않는다. 자세한 내용은
[[license-key-file-not-reapplied-when-config-present]] 참고.

**머신 바인딩**
리눅스에서는 `machine_id` + (`cpu_model` | `mem_total`) 로 판정하고 hostname 은 보지 않는다.
따라서 호스트 파일 3개를 마운트하면 컨테이너를 다시 만들어도 유지된다.
다만 **맥에서는 성립하지 않는다** — `/etc/machine-id`·`/proc` 가 없어 도커 VM 값이 들어오고
호스트와 다르다. 맥 도커에서의 라이선스 검증은 구조적으로 불가하며, 검증은 리눅스에서 해야 한다.

## 알려진 함정

- 이미지 태그가 안 맞으면 compose 가 레지스트리에서 받으려다 실패한다. 폐쇄망 최다 실패 원인
- `package.sh` 는 `--no-build` 여도 부속 이미지(nginx/postgres/qdrant)가 없으면 pull 한다
- 맥(Apple Silicon)에서 `linux/amd64` 이미지는 QEMU 에뮬레이션이라 느리고 jemalloc 경고가 뜬다 (무해)
- 서비스명이 `backend` 라 nginx 가 `http://backend:28000` 으로 프록시한다. 이름을 바꾸면 같이 바꿔야 한다
- **`models/` 만 소유권 자가치유에서 빠져 있다.** `docker-entrypoint.sh` 의 chown 목록은
  `config`·`log`·`hf_cache`·`query-results` 넷뿐이고, `:ro` 마운트라 넣어도 chown 이 안 된다.
  다른 마운트가 다 정상인데 모델만 안 보이는 상황이 나올 수 있다
- **맥(colima)에서는 바인드 마운트 권한이 강제되지 않는다.** 권한 문제는 리눅스에서만 드러난다
- **개발 서버의 `models/` 소유자가 1005 인 것은 우연이다.** 앱 UID 와 같아서 owner 비트로
  읽히고 있을 뿐이라, 권한 재현 시험을 그대로 하면 무효가 된다
- **고객사 서버는 rootless Docker 다.** 컨테이너 UID 0 → 호스트 사용자, 1 이상 → subuid
  (100000번대). 호스트 소유권을 내 계정으로 맞추려면 `--user $(id -u)` 가 아니라
  **`--user 0:0`** 이다. `sudo` 없이 컨테이너 경유로 `chown`/`chmod` 가 가능하다
  → [[knowledge/troubleshooting/rootless-docker-uid-mapping-inverted]]
- **고객사 서버 스토리지 드라이버가 `vfs` 다.** 4GB 이미지 적재에 수 시간,
  컨테이너 생성마다 이미지 전체 재복사. `down` 대신 `restart`,
  `--force-recreate` 는 compose 설정이 바뀐 경우에만 쓴다
  → [[knowledge/troubleshooting/docker-vfs-storage-driver-extreme-slowness]]
- **`user: "0:0"` 을 줘도 앱은 non-root 로 돈다.** 엔트리포인트가 chown 후 계정을 낮춘다.
  `docker exec ... id` 는 root 로 나오므로 실제 계정은 `docker top` 으로 봐야 한다
- **폐쇄망에서는 관리자 버튼이 안 뜬다.** 프론트가 외부 office.js 로드 결과로 게이팅한다
  → [[projects/dna-sql-agent-web/issues/admin-button-hidden-when-office-js-blocked|admin-button-hidden-when-office-js-blocked]]
