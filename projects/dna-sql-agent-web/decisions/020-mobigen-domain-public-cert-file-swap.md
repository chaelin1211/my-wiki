---
type: decision-record
project: dna-sql-agent-web
date: 2026-10-28
status: accepted
superseded-by: ""
tags: [https, nginx, deployment, certificate, domain, mobigen-server]
---

# ADR-020: mobigen 서버(구 dev) 도메인 연결 — 공인 인증서는 기존 마운트 경로에 파일만 교체

## 맥락

GitHub Actions(`dna-sql-agent-web_dev.yml`)로 배포하던 dev 서버에 도메인이 연결되고 공인 인증서를 발급받음.
이 도메인 버전 서버를 이후 **mobigen 서버**로 부름. 기존 mobigen 서버는 **monaco**로 이름 변경
(2026-10-29 `60a212e` — 워크플로우 `_mobigen.yml` → `_monaco.yml`, 변수 `MONACO_BASE_PATH`).
기존 HTTPS는 [[005-https-internal-ca-nginx]]의 내부 CA 방식(서버 IP 기준 사설 인증서)이었음.

nginx 컨테이너 구성(워크플로우 5단계, linko·monaco도 동일):

```yaml
-v /home/dnadev/ca:/etc/nginx/certs:ro \
-v ${{ github.workspace }}/nginx.conf:/etc/nginx/templates/default.conf.template:ro \
```

`nginx.conf`는 `/etc/nginx/certs/server.crt`, `server.key`를 참조하며 **dev·linko·monaco 워크플로우가 같은 파일을 공유**함.

## 선택지

### 옵션 A: 기존 마운트 경로에 같은 파일명으로 교체
- **장점:** nginx.conf·워크플로우 변경 없음, 다른 서버 영향 없음, `nginx -s reload`만으로 반영
- **단점:** 인증서 파일 이름이 고정(`server.crt`/`server.key`) — 받은 파일 이름을 바꿔 넣어야 함
- **비용/노력:** 낮음

### 옵션 B: 인증서 위치로 볼륨 매핑 변경 (예: `/etc/letsencrypt`)
- **장점:** 발급 도구가 만든 경로를 그대로 사용
- **단점:** 볼륨은 컨테이너 생성 시 고정되어 `docker restart`로 반영 안 됨 → 워크플로우 yml 수정·main 머지·재배포 필요.
  nginx.conf 경로까지 바꾸면 linko·monaco 배포 시 해당 경로에 인증서가 없어 nginx 기동 실패
- **비용/노력:** 보통

## 결정

**옵션 A를 선택한다.**

## 근거

공유 nginx.conf를 건드리지 않아 다른 서버 배포에 영향이 없고, 배포 파이프라인을 다시 돌릴 필요가 없음.
nginx는 파일 이름·확장자가 아닌 내용(PEM)만 읽으므로 이름만 맞추면 됨.

## 구현 (mobigen 서버에서 수행)

```bash
cd /home/dnadev/ca
mkdir -p ../ca-old && mv server.crt server.key ca.crt ca.key ../ca-old/

# server.crt 는 fullchain (서버 인증서 + 중간 인증서), PEM 형식
cp <발급 fullchain> server.crt
cp <발급 개인키> server.key
chmod 600 server.key

# 인증서-키 짝 확인 (두 해시 동일해야 함)
openssl x509 -noout -pubkey -in server.crt | openssl sha256
openssl pkey -pubout -in server.key | openssl sha256

docker exec nginx nginx -t && docker exec nginx nginx -s reload

openssl s_client -connect <도메인>:443 -servername <도메인> </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates
```

- PEM 여부: `head -1` 결과가 `-----BEGIN CERTIFICATE-----` / `-----BEGIN ... PRIVATE KEY-----`
- PFX/DER로 받았으면 `openssl pkcs12` / `openssl x509 -inform der`로 변환. PFX는 중간 인증서를 `-cacerts`로 꺼내 fullchain 구성
- 키가 암호화되어 있으면 nginx 기동 불가 → `openssl pkey`로 암호 해제 후 저장

## 결과

- mobigen 서버(구 dev)만 공인 인증서로 전환. 내부 CA 설치 없이 브라우저 경고 없음
- `ca.crt`·`ca.key`(ADR-005의 사설 CA)는 nginx가 쓰지 않음 → nginx 마운트 폴더 밖 `/home/dnadev/ca-old/`로 이동.
  다른 서비스가 참조하지 않는지 확인 후 정리
- linko·monaco 서버는 기존 방식 유지 (nginx.conf 공유 때문에 경로 고정)
- **갱신:** 만료 전 같은 방식으로 `server.crt`/`server.key`만 교체 후 reload
- **복구:** `ca-old/`의 `server.*`를 되돌리고 reload
- 재검토 시점: 다른 서버도 도메인·공인 인증서로 바뀌거나 자동 갱신(certbot 등) 도입 시 마운트 방식 재검토

## 서버 정보

| 항목 | 값 |
|------|-----|
| 대상 | mobigen 서버 (구 dev) — 워크플로우 `dna-sql-agent-web_dev.yml`, runner `[self-hosted, dev]` |
| 도메인 | TODO |
| 서버 IP | TODO |
| 인증서 발급처 | TODO |
| 인증서 만료일 | TODO |
| 인증서 위치 | `/home/dnadev/ca/server.crt` (fullchain), `/home/dnadev/ca/server.key` |
| 컨테이너 내부 경로 | `/etc/nginx/certs/` (읽기 전용) |
| 이전 인증서 백업 | `/home/dnadev/ca-old/` |
| BASE_PATH | 미설정 → 루트(`/`) 서비스. 하위 경로가 필요할 때만 repo 변수 `DEV_BASE_PATH` 등록 |

## 참고 자료

- [[005-https-internal-ca-nginx]] — 내부 CA + nginx 기본 구성
- [[014-multi-server-nginx-reverse-proxy]] — 서버 간 nginx.conf 공유
- [[015-http-addin-nginx-28001]] — 28001 HTTP 블록
- [[sessions/2026-10-28-mobigen-domain-certificate-swap]]
