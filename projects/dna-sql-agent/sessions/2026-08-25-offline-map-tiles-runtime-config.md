---
type: session-log
project: dna-sql-agent
date: 2026-08-25
duration: 
focus: "폐쇄망 미지원 항목 전수조사 → 지도 타일 런타임 설정 전환 · 배포 패키지 기동 검증"
tools-used: [claude-code]
outcome: success
---

# 2026-08-25 — 폐쇄망 지도 타일 런타임 설정 + 배포 패키지 로컬 검증

## 목표

폐쇄망에서 동작하지 않는 항목을 백엔드·웹 양쪽에서 훑고, 그중 지도 배경 타일을 재빌드 없이 사내 서버로 돌릴 수 있게 만든다.

## 수행한 작업

1. 폐쇄망 미지원 항목 전수조사 (백엔드 `src/dna` · 웹 전체)
   - 런타임 차단 4건: Plotly CDN, 지도 타일 6종, Office.js, Vercel Analytics
   - 백엔드 제품 코드에는 CDN 하드코딩 없음. GeoJSON은 자체 서빙, vanna legacy 경로는 죽은 코드
   - 임베딩 모델은 `resolve_model_path` 로 이미 대응됨 (`MODEL_ROOT` 사전 반입)
2. 지도 타일을 런타임 환경변수로 전환 (웹 PR #89)
   - `/map-config` 라우트가 요청 시점 `process.env` 를 읽어 내려줌
   - 지원하는 모드만 화면 토글에 노출, 남은 모드가 하나면 토글 자체를 감춤
   - 변수를 화면 용어에 맞춰 셋으로 확정
3. 배포 패키지 배선 (deploy 커밋 2건, PR 미생성)
   - compose 가 `.env` 값을 web 컨테이너로 전달, `.env.template`·`README.txt`·`INSTALL.txt` 안내 추가
4. 배포 패키지를 맥에서 실제로 기동해 검증
   - Docker 빌드 실패·이미지 용량·라이선스 3건을 차례로 규명
5. 차트 코드 리뷰 지적 5건을 이슈로 기록 (미검증·미수정)

## 핵심 결정

- **결정: 타일 설정을 빌드 타임 env 가 아니라 서버 라우트에서 런타임에 읽는다**
  → ADR: [[decisions/039-runtime-config-via-server-route]]
- **결정: 모드 단위로 "지원 여부"를 판정해 화면에 반영한다** — 없는 값을 다른 값으로 메우지 않고, 지정하지 않은 모드는 선택지에서 뺀다.
- **결정: 기본 모드에는 다크 변형을 두지 않는다** — OSM 표준 타일이 스타일 한 벌만 제공하므로, 변수를 넷에서 셋으로 되돌림.

## 배운 것

- **npm 의 lockfile 에 `libc` 가 없으면 gnu·musl 양쪽이 다 설치된다.** 그래서 alpine 에서 musl 바이너리를 명시 설치하던 우회책이 지금은 불필요하고, 아키텍처만 고정해 arm64 빌드를 막고 있었다.
- **라이선스 머신 판정은 OS 별로 규칙이 다르다.** Linux 경로는 hostname 을 아예 보지 않고 `machine_id` + (`cpu_model` 또는 `mem_total`) 로 판정한다. 맥·윈도우 경로만 hostname 을 본다.
- **컨테이너 안에서 읽는 머신 식별자는 호스트가 아니라 VM 의 것이다.** 맥에서는 colima VM 의 `/etc/machine-id`·`/proc/meminfo` 가 잡힌다.
- **Next.js 개발 서버는 `.env.production` 을 읽지 않는다.** dev 는 `.env.development`·`.env.local` 만 본다.
- 코드 리뷰 스킬은 현재 작업 디렉터리의 브랜치 diff 를 대상으로 돈다. 다른 저장소를 고쳤으면 그 저장소에서 돌려야 한다.

## 문제 & 해결

- **문제:** arm64 맥에서 웹 도커 빌드가 `EBADPLATFORM` 으로 실패
- **원인:** Dockerfile 이 `lightningcss-linux-x64-musl` 을 이름으로 못 박아 설치
- **해결:** 미적용. 그 줄을 뺀 빌드가 통과하는 것까지 확인
  → 이슈: [[projects/dna-sql-agent-web/issues/docker-arm64-build-hardcoded-x64-native-binary]]

- **문제:** 백엔드 이미지가 10.4GB
- **원인:** `models/` 가 `.dockerignore` 에 없어 2.2GB 가 구워짐(compose 가 어차피 마운트) + torch CUDA 빌드의 `nvidia/` 2.8GB
- **해결:** 미적용. 원인만 규명
  → 이슈: [[issues/backend-image-size-models-baked-and-cuda-torch]]

- **문제:** 맥에서 배포 패키지 기동 시 라이선스로 백엔드가 크래시 루프
- **원인:** 라이선스가 다른 PC 기준으로 발급됨. 첫 재발급도 실패했는데, Linux 판정 규칙을 잘못 읽어 `mem_total` 을 비워둔 탓
- **해결:** `machine_id` + `mem_total` 을 채워 재발급 → 기동 성공
  → 이슈: [[issues/license-linux-binding-ignores-hostname]]

## 다음 할 일

- [ ] deploy 저장소 PR 생성 (커밋 2건 로컬에만 있음)
- [ ] Plotly CDN 제거 — `plotly.js` 가 이미 의존성에 있으나 import 하지 않아 번들에 없음
- [ ] Office.js·Vercel Analytics 스크립트 제거
- [ ] 배포 이미지에 `HF_HUB_OFFLINE=1` 지정 검토 (모델 미반입 시 조용한 지연 대신 명확한 실패)
- [ ] 차트 리뷰 지적 5건 재현·수정
- [ ] 저장소 remote URL 에 박힌 PAT 폐기·교체

## 효과적이었던 프롬프트

```
폐쇄망 지원 안 되는 거 정리 좀 이거랑 웹
```

먼저 전수조사로 목록을 만들고 우선순위를 정한 뒤 한 항목씩 처리하는 흐름이 잘 맞았다.
설계 결정(교체 지점·변수 이름·모드 판정)은 구현 전에 선택지를 놓고 고르는 쪽이 손이 덜 갔다.
