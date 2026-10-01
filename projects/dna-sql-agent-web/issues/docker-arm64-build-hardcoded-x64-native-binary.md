---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-08-25
resolved: false
root-cause: "Dockerfile 이 x64 musl 네이티브 패키지를 이름으로 못 박아 설치해, arm64 빌드에서 npm 이 EBADPLATFORM 으로 거부"
tags: [docker, npm, arm64, alpine, lightningcss, tailwind]
---

# arm64 맥에서 웹 도커 빌드가 EBADPLATFORM 으로 실패

## 증상

```
npm error code EBADPLATFORM
npm error notsup Unsupported platform for @tailwindcss/oxide-linux-x64-musl@4.3.3:
  wanted {"os":"linux","cpu":"x64","libc":"musl"} (current: {"os":"linux","cpu":"arm64","libc":"musl"})
ERROR: failed to solve: process "/bin/sh -c npm install lightningcss-linux-x64-musl @tailwindcss/oxide-linux-x64-musl" did not complete successfully
```

## 환경

- `Dockerfile:15`
- Apple Silicon + colima(aarch64 VM). `docker build` 에 `--platform` 을 주지 않은 경우
- 서버 러너(x86)와 `--platform linux/amd64` 빌드에서는 재현되지 않음

## 왜 여태 안 났나

이 저장소 이미지는 x86 self-hosted 러너에서 빌드돼 왔고, 맥에서 만든 이전 이미지도 `linux/amd64` 였다(로컬 `dna-sql-agent-web:1.0` 확인). colima 를 aarch64 로 쓰면서 platform 을 지정하지 않자 처음 드러났다.

## 근본 원인

`npm ci` 가 musl 바이너리를 빼먹는다고 보고 명시 설치를 넣은 우회책이다(`6719ce7`, 그 전에는 `npm rebuild lightningcss`). 그러나 지금은 필요하지 않다.

`package-lock.json` 의 네이티브 패키지 항목에 `libc` 필드가 없어 musl 용과 gnu 용의 제약이 `cpu=[arm64] os=[linux]` 로 동일하다. npm 이 둘을 구분하지 못해 **양쪽을 다 설치**하므로, 필요한 musl 바이너리는 `npm ci` 만으로 들어온다. alpine 컨테이너에서 확인:

```
lightningcss-linux-arm64-gnu
lightningcss-linux-arm64-musl   ← npm ci 가 이미 설치
oxide-linux-arm64-gnu
oxide-linux-arm64-musl
```

덤으로 이 줄은 버전을 고정하지 않아, lockfile 이 고정한 4.2.1 대신 latest(4.3.3)를 끌어온다.

## 해결 방법

미적용. 그 줄을 삭제하면 된다. 아키텍처 분기도 필요 없다.

```dockerfile
# 삭제
RUN npm install lightningcss-linux-x64-musl @tailwindcss/oxide-linux-x64-musl
```

그 줄을 뺀 Dockerfile 로 빌드가 통과하고, 이미지를 띄워 CSS 번들 생성과 라우트 응답까지 확인했다. **단 arm64 에서만 검증했다.** 원리상 x64 도 동일하나 실측하지 않았다.

배포용 이미지를 맥에서 만들 때는 platform 을 명시해야 한다. 대상 서버가 x86 이므로 arm64 이미지는 거기서 돌지 않는다.

```bash
docker build --platform linux/amd64 -t dna-sql-agent-web:1.0 .
```
