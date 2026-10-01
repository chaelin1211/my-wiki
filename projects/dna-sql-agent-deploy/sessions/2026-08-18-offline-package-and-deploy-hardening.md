---
type: session-log
project: dna-sql-agent-deploy
date: 2026-08-18
duration:
focus: "폐쇄망 임베딩 모델 공급 + 배포 스크립트 운영성 정리"
tools-used: [claude-code]
outcome: success
---

# 2026-08-18 — 폐쇄망 임베딩 모델 + 배포 스크립트 정리

## 목표

폐쇄망 고객이 기동할 때 huggingface.co 에서 모델을 받지 못해 기동에 실패하는 문제를
해결하고, 그 과정에서 드러난 배포 스크립트의 진단·설정 문제를 함께 정리한다.

## 수행한 작업

1. **임베딩 모델을 컨테이너 밖으로 뺐다.** `MODEL_DIR` 을 `/data/apps/dna_sql_agent/models` 로
   읽기 전용 마운트하고, 앱이 로딩 직전에 `resolve_model_path()` 로 로컬/다운로드를 판별한다.
   → ADR: [[001-offline-embedding-model]]
2. **`package.sh --with-models`** 를 추가했다. 폐쇄망 고객에게만 붙이며, 없으면 기존 동작 그대로다.
   매번 2GB 를 다시 받지 않도록 `MODEL_CACHE_DIR`(기본 `~/.cache/dadap-models`)에 캐시한다.
   캐시를 쓸 수 없어도 중단하지 않고 스테이징에 바로 받는다.
3. **`start.sh` 진단을 고쳤다.** 기동 전 라이선스 키 확인, 대기 중 백엔드 로그 출력,
   크래시 루프면 15분 기다리지 않고 즉시 중단.
4. **서버 포트를 `.env` 로 뺐다.** `HTTP_PORT` / `HTTPS_PORT` / `INTERNAL_HTTP_PORT` / `BACKEND_PORT`.
   컨테이너 내부 포트는 nginx 설정과 맞물려 있어 그대로 둔다.
5. **라이선스 판정용 호스트 식별자를 마운트했다.** `/etc/machine-id`, `/proc/cpuinfo`, `/proc/meminfo`.
   배포 워크플로(linko/mobigen)가 이미 하던 것을 compose 에 반영.
6. 문서 정리 — README 의 잘못된 캐시 경로 안내 정정, 라이선스 절 신설, INSTALL 에 키 배치 단계 추가.

## 핵심 결정

- **설정에는 모델 "이름"을 그대로 둔다.** 경로로 바꾸면 폐쇄망/개방망 패키지가 갈리고 관리자
  화면에도 경로가 노출된다. 앱이 로딩 직전에 한 번 해석하게 해서 한 패키지로 두 환경을 덮는다.
  인증서 유무로 `nginx.conf` 를 정하는 기존 `init.sh` 방식과 같은 결이다.

- **HF 캐시가 아니라 flat 디렉터리로 전달한다.** 캐시 레이아웃은 huggingface_hub 의 내부
  구현이라 배포 포맷으로 부적합하다. 다만 모델을 내려받는 구성에서는 `hf_cache` 볼륨이
  여전히 필요해서, "모델이 사는 곳이 둘"이 되는 것은 감수했다. 재다운로드 비용이 더 크다.

- **`ADMIN_PORT` → `INTERNAL_HTTP_PORT`.** 관리자 전용처럼 읽히지만 실제로는 80/443 과 같은
  화면·API 를 평문으로 여는 포트다. 이름에 "평문"이 드러나야 방화벽 정책을 정할 수 있다.
  실사용 흔적이 없어 삭제도 검토했으나, 인증서 이름 불일치 우회라는 용도가 유효해 남기고
  `.env.template` 에 설명을 붙였다.

## 배운 것

- **`.gitignore` 는 이미 추적 중인 파일에 소급되지 않는다.** 규칙을 나중에 추가해도
  이전에 커밋된 파일은 계속 추적된다. `git rm --cached` 가 필요하다.
- **도커는 bind mount 의 호스트 경로가 없으면 만들어 준다.** `init.sh` 를 돌리지 않았는데
  `data/`·`log/` 가 생긴 것은 그 때문이었다. 리눅스에서는 root 소유가 되어 권한 문제가 된다.
- **`docker compose logs --since` 는 타임존 없는 값을 지역 시간으로 읽는다.** UTC 로 만든
  타임스탬프에 `Z` 를 빼먹으면 KST 에서 9시간치 로그를 매번 다시 출력한다.
- **`restart: always` 가 걸린 컨테이너는 기동 실패 시 `exited` 가 아니라 `restarting`** 이다.
  `exited` 만 보는 검사는 한 번도 걸리지 않는다.
- **`.dockerignore` 에 Dockerfile 을 넣어도 빌드는 정상이다.** 컨텍스트와 별개로 전달되며
  `COPY` 대상에서만 빠진다. Nuitka 로 소스를 감추면서 빌드 방법을 이미지에 넣고 있었다.
- **맥에서는 컨테이너 라이선스 검증이 구조적으로 불가하다.** `/etc/machine-id`·`/proc` 가
  없어 도커 VM 값이 들어오고 호스트와 다르다. 검증은 리눅스에서 해야 한다.

## 남은 것

- 라이선스 시크릿 전달 방식, 머신 바인딩 정책 → [[../../2026/kacportal/status]] 의 "열린 질문"
- Qdrant 클라이언트(1.17.0) / 서버(v1.12.4) 버전 불일치
- 도구 권한 경고 필터가 등록 실패까지 숨기는 문제 (보류)
- 리눅스 장비에서 폐쇄망 전 과정 검증
