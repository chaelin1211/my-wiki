---
type: decision-record
project: dna-sql-agent-web
date: 2026-06-16
status: accepted
superseded-by: ""
tags: [nginx, deployment, multi-server, cors, docker]
---

# ADR-014: 다중 서버 배포 — nginx 리버스 프록시로 API URL 통일

## 맥락

프론트엔드를 여러 서버에 배포해야 하는 상황. `.env.production`에 백엔드 IP가 하드코딩(`http://192.168.101.129:28000`)되어 있어 서버마다 다른 이미지를 빌드해야 했다.

`NEXT_PUBLIC_*` 변수는 빌드 타임에 번들에 인라인되므로 런타임에 변경 불가.

## 선택지

### 옵션 A: 서버마다 build arg로 IP 주입
- **장점:** 단순, 추가 인프라 불필요
- **단점:** 서버 수만큼 빌드 필요, 워크플로우에 IP 노출

### 옵션 B: nginx 리버스 프록시 (상대경로)
- **장점:** 이미지 하나로 모든 서버 배포, IP 설정 불필요, CORS 문제 자동 해결
- **단점:** nginx 설정 필요
- **비용/노력:** 낮음 (이미 nginx 사용 중)

## 결정

**옵션 B (nginx 리버스 프록시)를 선택한다.**

## 근거

어차피 HTTPS를 위해 nginx를 쓰고 있어서 추가 인프라 없이 적용 가능. 브라우저에서 `/api/v1/...` 요청이 같은 origin으로 인식되어 CORS 문제도 자동으로 해결됨.

## 구현

### `.env.production`
```
NEXT_PUBLIC_API_BASE_URL=
```

### `nginx.conf` — `/api`, `/health` 백엔드 프록시 추가
```nginx
location ~ ^/(api|health) {
    proxy_pass http://localhost:28000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto https;
}

location / {
    proxy_pass http://localhost:28001;
    ...
}
```

## 결과

- 서버 추가 시 nginx.conf, 워크플로우 변경 없이 배포 가능
- CORS: nginx 프록시로 same-origin 처리되어 백엔드 CORS 설정에서 서버 IP 불필요
- 백엔드 CORS는 `localhost`와 개발/addin 주소만 허용하면 됨

## 메모 — Docker 네트워크 구성 개선 여지

현재 nginx 컨테이너는 `--network host`를 사용 중. 정석은 Docker bridge network로 컨테이너 간 통신하는 것:

```
Docker network (bridge)
  ├── nginx → proxy_pass http://dna-sql-agent-web:28001
  ├── dna-sql-agent-web
  └── dna-sql-agent
```

다만 dev 서버에서 `--publish`가 불가한 원인(방화벽 등) 미파악 상태. 두 서버가 같은 `nginx.conf`를 공유하므로 한쪽만 바꾸면 충돌. 추후 원인 파악 후 개선 검토.

## 참고 자료

- [[005-https-internal-ca-nginx]] — nginx 컨테이너 기본 구성
