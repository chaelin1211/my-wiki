---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-17
resolved: true
root-cause: "서버 iptables FORWARD 체인 DROP 정책"
related: []
tags: [docker, networking, iptables]
---

# Docker 커스텀 네트워크 컨테이너 간 통신 불가 (iptables FORWARD DROP)

## 증상

```
docker exec nginx ping -c 3 172.17.0.3
3 packets transmitted, 0 packets received, 100% packet loss

docker exec nginx curl -v --max-time 5 http://dna-sql-agent-web:3000
* Trying 172.17.0.3:3000...
* Connection timed out after 5002 milliseconds
```

같은 Docker 커스텀 네트워크(dna-net)에 있는 컨테이너끼리 ping/TCP 연결이 불가.

## 환경

- **OS:** Linux (온프레미스 서버)
- **Docker:** 커스텀 브릿지 네트워크 `dna-net`
- **컨테이너:** nginx, dna-sql-agent-web (모두 dna-net 소속 확인)
- **재현 조건:** 해당 서버에서 Docker 커스텀 네트워크 사용 시 항상 발생

## 시도한 것들

1. ❌ `docker network inspect`로 서브넷 확인 — 기본 브릿지와 겹치지 않음
2. ❌ `ip route`로 라우팅 확인 — br-57559c912ee8로 정상 라우팅됨
3. ❌ `docker inspect` 양쪽 컨테이너 네트워크 확인 — 동일 NetworkID
4. ✅ `--network host`로 전환 → 정상 동작

## 근본 원인

서버의 iptables FORWARD 체인 정책이 DROP. Docker는 커스텀 네트워크 사용 시 컨테이너 간 트래픽을 브릿지 인터페이스를 통해 전달하는데, 이 트래픽이 FORWARD 체인을 거침. DROP 정책으로 모든 포워딩 패킷이 차단됨.

## 해결 방법

모든 컨테이너를 `--network host`로 통일. nginx는 호스트 네트워크에서 `localhost:3000`, `localhost:28000`으로 프록시.

```yaml
# 워크플로우에서
docker run -d --network host ...
```

임시 해결책(재부팅 시 소멸):
```bash
iptables -I FORWARD -i br-<network-id> -o br-<network-id> -j ACCEPT
```

## 예방책

- 서버에 커스텀 방화벽이 있는 환경에서는 Docker 커스텀 네트워크 사용 전 FORWARD 체인 확인: `iptables -L FORWARD -n | head`
- 엄격한 방화벽 환경에서는 `--network host`가 실용적 대안

## 관련 페이지

- [[knowledge/troubleshooting/docker-custom-network-iptables-forward]]
