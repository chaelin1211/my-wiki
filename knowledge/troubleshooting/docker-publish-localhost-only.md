---
type: troubleshooting
tags: [docker, networking, security, firewall]
---

# Docker --publish 외부 노출 차단 — 127.0.0.1 바인딩

## 상황

Docker `--publish 3000:3000`은 `0.0.0.0:3000`에 바인딩되어 외부에서 직접 접근 가능. 서버 방화벽이 막아도 Docker가 iptables DOCKER 체인으로 우회해서 뚫림.

nginx 뒤에 있는 앱 컨테이너(Next.js 등)를 외부에서 직접 접근 못하게 막고 싶을 때 문제.

## 해결

```bash
# 외부 노출됨 (0.0.0.0 바인딩)
--publish 3000:3000

# 로컬에서만 접근 가능 (127.0.0.1 바인딩)
--publish 127.0.0.1:3000:3000
```

`127.0.0.1:3000:3000`으로 설정하면 외부에서 `서버IP:3000`으로 직접 접근 불가. nginx(--network host)는 localhost:3000으로 프록시 가능.

## 적용 예시

```yaml
# workflow에서
docker run -d \
  --name dna-sql-agent-web \
  --publish 127.0.0.1:3000:3000 \
  --restart always \
  dna-sql-agent-web:latest
```

## 주의

- `--network host` 사용 시에는 이 설정이 의미 없음 (포트 매핑 자체가 없으므로 방화벽 정책에 따름)
- nginx가 같은 호스트에서 `--network host`로 뜨면 `localhost:3000` 접근 가능
