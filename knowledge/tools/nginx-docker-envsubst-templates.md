---
type: knowledge
tags: [nginx, docker, reverse-proxy, envsubst, deployment]
created: 2026-10-16
updated: 2026-10-16
---

# nginx 공식 이미지 템플릿(envsubst)과 하위 경로 프록시

## 템플릿 기능

공식 `nginx` 이미지(1.19+)는 기동 시 `/etc/nginx/templates/*.template` 을 envsubst 해서
`/etc/nginx/conf.d/` 에 쓴다.

```yaml
environment:
  NGINX_ENVSUBST_FILTER: ^BASE_PATH      # 이 패턴의 변수만 치환
  BASE_PATH: ${BASE_PATH:-}
  BASE_PATH_ROOT: ${BASE_PATH:-/}        # 빈 값일 때 대체값은 compose 에서 계산
volumes:
  - ./nginx.conf:/etc/nginx/templates/default.conf.template:ro
```

- 필터 없이 쓰면 `HOSTNAME`·`PATH` 등 정의된 모든 환경변수가 치환 대상. nginx 변수(`$host`)와 겹칠
  일은 적지만 범위를 좁혀 두는 게 안전
- **빈 값으로 정의된 변수도 치환됨** (`$1`·`$2` 같은 캡처는 envsubst 대상 아님)
- 주석에 `${VAR}` 를 쓰면 주석도 치환됨 → 주석엔 변수 표기 피하기
- GitHub Actions 에서는 `-e BASE_PATH_ROOT="${{ vars.X || '/' }}"`

## 앞단이 경로를 떼든 붙이든 받는 location

```nginx
location ~ ^(${BASE_PATH})?/(api|health)(/|$) {
    rewrite ^(${BASE_PATH})?(/.*)$ $2 break;      # API 는 항상 떼서 백엔드로
    proxy_pass http://backend:28000;
}
location / {
    rewrite ^(${BASE_PATH})?/$ ${BASE_PATH_ROOT} break;          # / 와 /x/ → /x
    rewrite ^(?!${BASE_PATH}(/|$))(.*)$ ${BASE_PATH}$2 break;    # 없으면 붙임
    proxy_pass http://web:3000;
}
```

- `BASE_PATH` 가 비면 모든 rewrite 가 무해하게 통과 → 기존 설정과 동일 동작
- 루트는 **`/x` (끝 슬래시 없음)** 로 보내야 함. `/x/` 로 보내면 Next 가 308 로 `/x` 로 돌리고,
  앞단이 `/x` → `/x/` 로 보정(prefix location 자동 301)하면 무한 루프
- `rewrite ... break` 후 URI 없는 `proxy_pass` 는 바뀐 URI 를 그대로 전달, 쿼리스트링도 유지
- regex location 이 prefix `location /` 보다 먼저 평가됨
- `(/|$)` 로 끝을 막아 `/apidocs` 같은 경로가 API 로 새지 않게

## X-Accel-Buffering 은 다음 프록시로 안 넘어감

백엔드가 SSE 응답에 `X-Accel-Buffering: no` 를 주면 nginx 는 그 응답 버퍼링을 끈다. 그런데 nginx 는
`X-Accel-*` 헤더를 **소비하고 지운다**(기본 `proxy_hide_header`). 앞단에 프록시가 하나 더 있으면
그쪽은 헤더를 못 받아 버퍼링 → 스트리밍이 끝난 뒤 한꺼번에 보임.

```nginx
proxy_pass_header X-Accel-Buffering;   # 앞단 nginx 도 버퍼링을 끄게 전달
```

앞단이 nginx 가 아니면(Apache, ALB 등) 이 헤더를 모를 수 있어 별도 설정 필요.

## 검증 방법

같은 nginx 컨테이너에 가짜 업스트림을 띄워 경로만 찍게 하면 빠르게 라우팅을 확인할 수 있다.

```nginx
server { listen 28000; location / { add_header X-Accel-Buffering no; return 200 "backend $request_uri\n"; } }
server { listen 3000;  location / { return 200 "web $request_uri\n"; } }
```
`--add-host backend:127.0.0.1 --add-host web:127.0.0.1` 로 업스트림 이름을 맞추고 `curl` 로 경로별 결과 확인.
Docker Hub 429 가 나면 `public.ecr.aws/docker/library/nginx` 미러 사용.

## 관련

- [[projects/dna-sql-agent-web/decisions/019-runtime-base-path-placeholder-substitution|ADR-019]]
- [[projects/dna-sql-agent-web/decisions/014-multi-server-nginx-reverse-proxy|ADR-014]]
- [[knowledge/tools/nextjs-runtime-base-path]]
