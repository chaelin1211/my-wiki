---
type: decision-record
project: dna-sql-agent-web
date: 2026-05-26
status: accepted
superseded-by: ""
tags: [https, nginx, deployment, cors]
---

# ADR-005: 내부망 HTTPS 설정 — 내부 CA + nginx 컨테이너

## 맥락

도메인 없는 내부망 환경에서 Docker로 배포된 Next.js 웹에 HTTPS를 적용해야 했다.
공인 CA 사용 불가(도메인 없음), Let's Encrypt 사용 불가(외부 접근 불가) 조건.

## 선택지

### 옵션 A: 자체 서명 인증서 (Self-signed)
- **장점:** 설정 간단
- **단점:** 접속하는 모든 브라우저에서 매번 경고창, 수동 예외 처리 필요
- **비용/노력:** 낮음

### 옵션 B: 내부 CA 인증서
- **장점:** CA를 클라이언트에 한 번 설치하면 이후 경고 없음
- **단점:** 접속하는 PC마다 CA 인증서 설치 필요
- **비용/노력:** 보통

## 결정

**옵션 B (내부 CA)를 선택한다.**

## 근거

팀원 다수가 매일 접속하는 서비스이므로 매번 브라우저 경고를 수동으로 무시하는 방식은 UX 저하가 크다.
CA를 한 번만 배포하면 이후 경고 없이 사용 가능하다.

## 구현

### 내부 CA 생성 (서버에서 1회)

```bash
mkdir -p /home/dnadev/ca && cd /home/dnadev/ca

# CA 키 & 인증서
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
  -out ca.crt -subj "/CN=DnA Internal CA/O=DnA/C=KR"

# 서버 키 & CSR
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
  -subj "/CN=<서버IP>/O=DnA/C=KR"

# SAN 설정 (IP 기반 필수)
cat > san.ext << EOF
[req]
distinguished_name = req_distinguished_name
[req_distinguished_name]
[SAN]
subjectAltName=IP:<서버IP>
EOF

# CA로 서버 인증서 서명
openssl x509 -req -in server.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 365 -sha256 \
  -extfile san.ext -extensions SAN
```

### nginx.conf (repo 루트)

```nginx
server {
    listen 443 ssl;
    ssl_certificate     /etc/nginx/certs/server.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;

    location / {
        proxy_pass http://localhost:28001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
    }
}

server {
    listen 80;
    return 301 https://$host$request_uri;
}
```

### GitHub Actions workflow (nginx 스텝 추가)

```yaml
- name: Run Nginx Container
  run: |
    docker stop nginx || true
    docker rm nginx || true
    docker run -d \
      --name nginx \
      --network host \
      -v /home/dnadev/ca:/etc/nginx/certs:ro \
      -v ${{ github.workspace }}/nginx.conf:/etc/nginx/conf.d/default.conf:ro \
      --restart always \
      nginx:alpine
```

### 클라이언트 CA 설치

```bash
# macOS
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain ca.crt

# Windows (PowerShell 관리자)
Import-Certificate -FilePath ca.crt -CertStoreLocation Cert:\LocalMachine\Root

# Ubuntu/Debian
sudo cp ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

## 결과

- Next.js 컨테이너는 변경 없이 그대로 유지 (`--network host`, port 28001)
- nginx 컨테이너가 443 → localhost:28001 프록시 역할
- **CORS 이슈 발생**: 브라우저가 직접 API 서버를 호출하는 구조에서 origin이 `http://` → `https://`로 바뀌어 CORS 오류 발생 → API 서버 CORS 정책에 `https://<서버IP>` 추가하여 해결
- 인증서 만료(1년) 시 `server.key`, `server.crt`만 재발급, CA는 재사용

## 참고 자료

- 인증서 위치: `/home/dnadev/ca/`
- Next.js 포트: 28001
