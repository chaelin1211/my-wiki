---
type: session-log
project: dna-sql-agent
date: 2026-08-06
duration: 반나절
focus: "임베딩 모델 폐쇄망 대응 조사 + 배포 하드닝 1차 마무리(PR 2건)"
tools-used: [claude-code, docker, github-actions, gh-cli, pytest, next]
outcome: success
---

# 2026-08-06 — 임베딩 모델 번들링 조사와 배포 하드닝 1차 마무리

## 목표

폐쇄망에서 임베딩 모델을 런타임에 HuggingFace 에서 받다 기동이 막히는 문제를
조사하고, 이미지 번들링 방안을 정한다. 이어서 `chore/deploy-hardening` 을
PR 까지 올려 1차를 닫는다.

## 수행한 작업

### 1. 임베딩 모델 폐쇄망 조사

**대상은 `upskyy/bge-m3-korean` 하나뿐이다.** 다른 HF 다운로드(reranker 등)는 없다.
로드 지점은 세 곳이고 셋 다 `SentenceTransformer(HF repo id)` 를 그대로 호출한다.

| 위치 | 모델명 출처 |
|---|---|
| `agent_service.py:136` → `LocalEmbeddingService` (`retriever.py:146`) | `config/embedding.json` |
| `vectorization/embedder.py:25` | 호출자가 전달 |
| `vectorization/orchestrator.py:54` | **하드코딩 상수** |

색인(벡터화)과 질의 양쪽에 쓰이므로, 없으면 RAG 검색 자체가 동작하지 않는다.

배포 저장소는 이 문제를 문서로 떠넘기고 있었다 — `INSTALL.txt`·`README.txt`·
`.env.template` 모두 "최초 기동 시 인터넷에서 약 2GB 내려받음, 폐쇄망이면 미리
받아 두십시오". compose 에 HF 캐시 볼륨도 없어 컨테이너 재생성 시 재다운로드된다.

**설계안** — Dockerfile 에 모델 전용 스테이지를 추가해 빌드 시점에 받아 굽고,
코드에는 얇은 경로 해석기만 넣는다. HF 캐시 디렉토리(`HF_HOME`) 통째로 굽는 방식도
검토했으나, blobs↔snapshots 심볼릭 링크가 `docker save`/`unzip` 을 타며 깨질 여지와
락 파일 쓰기 권한 문제가 있어 **평범한 디렉토리**(`/opt/models/...`)로 정했다.

### 2. 이미지 용량 실측 — 예상 밖의 발견

번들링 비용(+2.1GB)을 재려고 이미지를 뜯어봤더니 **콘텐츠 8.08GB 중 4.2GB 가
쓰지 않는 CUDA 스택**이었다.

```
nvidia-*-cu12                      2.8GB
triton                             419MB
torch/lib/libtorch_cuda.so         816MB
torch/lib/libtorch_cuda_linalg.so   82MB
torch/lib/libcusparseLt.so          33MB
```

실측 휠 크기: `torch-2.2.2+cpu` **178MB** vs `torch-2.2.2+cu118` **781MB**.

`requirements.txt` 첫 줄 `--find-links .../cu118` 은 **의도대로 동작하지 않고 있었다.**
설치된 것은 `nvidia-*-cu12` 계열 — PyPI 기본 휠(cu121)이 이겼다. `--find-links` 는
우선순위를 강제하지 않는다.

그 밖에: `chromadb`(+onnxruntime 52MB, kubernetes 76MB, rust_bindings 53MB)는
`src/dna/` 어디서도 import 하지 않는다(pip `vanna` 도 요구하지 않음). `nuitka`·
`mypy`·`pytest`·`zstandard` 등 빌드 전용 도구 ~110MB 가 `/opt/venv` 에 설치되어
final 스테이지로 통째 복사된다.

**"안 쓰는 4.2GB 를 빼고 필요한 2.1GB 를 넣으면 오히려 2GB 작아진다"** 는 결론까지
갔으나 — **원격 배포를 확인해 보니 `device: cuda` 로 실사용 중이었다.** CPU 전용
단일 이미지 안은 폐기하고 CPU/GPU 두 벌 빌드로 방향을 바꿨다.

### 3. 배포 저장소 diff 리뷰 → 커밋 4건

`dna-sql-agent-deploy` 의 미커밋 변경(pigz 병렬 압축, 워크플로 site/rebuild 입력)을
리뷰하고 정리했다.

- `d5c5391` pigz 압축, `0eebae8` 워크플로 사이트·빌드 옵션 (기존 변경 커밋)
- `5054d17` 동작하지 않는 `site` 입력 주석 처리
- `86e96ff` **boolean 입력 비교 오류 수정** (아래 문제 & 해결)

`sites/mobigen/env.overlay` 는 시크릿(`DB_ENCRYPTION_KEY`·DB 비밀번호·`LLM_API_KEY`·
내부망 IP)이 든 채 untracked 상태였다. `.gitignore` 에 `sites/` 가 없어 `git add -A`
한 번이면 올라간다. 커밋에서 제외하고 그대로 뒀다.

### 4. 1차 마무리 — PR 2건

- **백엔드** `dna-sql-agent#131` (24커밋) — 머지 전에 `dna-sql-agent_dev.yml` 의
  `ref: chore/deploy-hardening` 하드코딩을 `main` 으로 되돌림(`ad39d1d`).
  안 되돌리면 머지 후 브랜치 삭제 시 DEV 배포가 깨진다
- **웹** `dna-sql-agent-web#76` (3커밋) — 브랜치가 원격에 없어 새로 푸시.
  `172.16.1.7` 은 출처를 알 수 없어 제거하고 `addin.dnadev.com` 만 남김(`daaa173`)

검증: 백엔드 `PYTHONPATH=src pytest` **56개 통과**, 웹 프로덕션 빌드 성공 +
`.next/` 산출물에 사내 주소 없음 확인.

## 핵심 결정

- **CPU 전용 이미지 안 폐기, CPU/GPU 두 벌 빌드로.** 원격이 `device: cuda` 로
  돌고 있음을 확인. `.env.template`·`README.txt` 에 "GPU 서버라면 device 를 cuda 로"
  라고 이미 문서화되어 있어, CPU 전용은 약속을 깨는 것이 된다
  → ADR 은 방식 확정 후 작성 (미확정)

- **HF 캐시 대신 평범한 디렉토리로 번들.** 심볼릭 링크·락 파일 문제를 피한다

- **배포 워크플로의 빌드 경로를 유지.** "빌드는 소스 저장소가, 패키징은 배포
  저장소가" 로 분리하자고 제안했으나(중복 제거·PAT 불필요), 사용자가 현행 유지를
  택함. 단 `SOURCE_REPOS_TOKEN` 이 미등록이라 빌드를 켜면 여전히 실패한다

## 배운 것

- **모델 가중치에는 CPU용/GPU용 구분이 없다.** `safetensors` 는 device 무관하게
  같은 파일이다. 용량을 먹는 것은 PyTorch 라이브러리 쪽(CUDA 커널·NVIDIA 런타임)
- **`--find-links` 는 우선순위를 강제하지 않는다.** cu118 을 적어 두고 cu121 이
  설치되고 있었다. 인덱스를 고정하려면 `--index-url` 을 써야 한다
- **도커 빌드 컨텍스트는 클라이언트가 읽어 데몬으로 전송한다.** `DOCKER_HOST` 로
  원격 데몬을 써도 소스는 실행하는 쪽 파일시스템에 있어야 한다
  → [[knowledge/troubleshooting/docker-build-context-sent-from-client]]
- **`next build` 는 config 를 읽기 전에 `NODE_ENV=production` 을 스스로 설정한다.**
  Dockerfile 이 `NODE_ENV` 없이 `npm run build` 를 해도 프로덕션 분기가 탄다
- **`allowedDevOrigins` 는 CORS 가 아니다.** Next 15.2+ 의 개발 서버 전용 안전장치로,
  dev 서버 내부 엔드포인트(HMR·`/_next/*`)에 대한 교차 출처 요청을 막는다.
  프로덕션에는 대응물 자체가 없다. 웹 저장소에는 CORS 처리가 전혀 없다

## 문제 & 해결

- **문제:** "이미지 새로 빌드"를 **껐는데도** 소스 체크아웃 스텝이 실행되어
  `Input required and not supplied: token` 으로 워크플로 실패
- **원인:** `workflow_dispatch` 의 `type: boolean` 입력이 표현식에서 **문자열**로
  들어온다. `if: ${{ inputs.rebuild }}` 는 `"false"` 가 빈 문자열이 아니라 **항상 참**
- **해결:** `github.event.inputs.rebuild == 'true'` 로 문자열 명시 비교.
  `!inputs.rebuild` 를 쓰던 `묶을 이미지 확인` 스텝은 **항상 건너뛰고** 있었고,
  그 스텝이 버전 태그를 붙이므로 어떤 설정으로도 성공할 수 없는 상태였다
  → 이슈: [[projects/dna-sql-agent/issues/github-actions-boolean-input-always-truthy]]

- **문제:** 브랜치 변경분에 이미 머지된 Nuitka 작업이 섞여 보임
- **원인:** 로컬 `main` 이 **40커밋 뒤처져** 있었다. `main..HEAD` 로 세서 오판
- **해결:** `origin/main..HEAD` 로 재산정(24커밋). 사용자가 먼저 알아챘다
  → 기존 이슈와 동일: [[knowledge/troubleshooting/git-diff-stale-local-branch-shows-merged-commits-as-new]]

## 다음 할 일

- [ ] PR #131 제목 확정 — "배포 경로 하드닝" 이 모호. `refactor: 접속정보를 .env
      직독으로 전환하고 배포 이미지·마운트 정리` 안 제시함 (미확정)
- [ ] PR #131 본문 보강 — 엔트리포인트 항목 설명 확장, `관측 접속정보` → `LANGFUSE_*`
      구체화, 예외 원문 노출의 **잔존 범위** 명시
- [ ] 임베딩 모델 이미지 번들링 구현 (CPU/GPU 두 벌)
- [ ] `requirements.txt` 3분할 + Dockerfile `TORCH_VARIANT` ARG
- [ ] `chromadb` 제거 (~200MB) — Nuitka 가 `vanna/legacy/chromadb` 컴파일 시 경고 확인 필요
- [ ] 빌드 전용 도구를 런타임 venv 에서 분리 (~110MB)
- [ ] `orchestrator.py` 의 모델명·device 하드코딩 → config 사용
- [ ] `sites/*/env.overlay` 를 `.gitignore` 에 추가
- [ ] `SOURCE_REPOS_TOKEN` 등록 또는 빌드 경로 제거
- [ ] pigz 로컬 판정/원격 실행 불일치 (`--remote-compress`)
- [ ] 예외 원문 노출 잔존 — `bookmarks/routes.py:485,515,583`, `auth` 5곳, `group_admin` 5곳
- [ ] 웹 타입 오류 11건 (`components/bi-slide/*`, `ignoreBuildErrors: true` 로 가려짐)

## 효과적이었던 프롬프트

```
"근데 그거 이미 머지 된 내용인거 같은데?"
"아니 근데 웹에서 cors 체크를 해?"
"근데 node_env가 설정 안 되어있으면 172. 주소가 포함되어야 하는거 아냐?"
"배포 경로 하드닝이 머냐"
```

전부 내 설명의 틀린 부분·모호한 부분을 정확히 짚은 질문이다. 특히 첫 번째는
stale 로컬 `main` 이라는 실제 오류를 잡아냈고, 세 번째는 서로 다른 두 검증을
같은 표에 섞어 놓은 것을 드러냈다. 결론이 맞아도 근거가 틀렸으면 지적받았다.
