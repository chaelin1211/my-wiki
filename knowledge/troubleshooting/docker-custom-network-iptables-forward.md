---
type: troubleshooting
tags: [docker, networking, iptables, linux]
---

# Docker 커스텀 네트워크 — 컨테이너 간 통신 불가 (iptables FORWARD DROP)

## 증상

- 같은 Docker 커스텀 네트워크 컨테이너끼리 ping 100% 패킷 손실
- `curl`이 connection timeout (connection refused가 아님)
- DNS 해석은 정상 (컨테이너 이름 → IP 조회 성공)
- 라우팅 테이블도 정상 (`ip route`에 브릿지 인터페이스 항목 존재)

## 원인

서버의 iptables FORWARD 체인 기본 정책이 DROP. Docker 커스텀 네트워크의 컨테이너 간 트래픽은 호스트 브릿지 인터페이스를 거쳐 FORWARD 체인을 통과함. DROP 정책이 이를 차단.

```bash
# 확인 방법
iptables -L FORWARD -n | head -5
# Chain FORWARD (policy DROP) 이면 문제
```

## 해결책

**방법 1 (즉시, 재부팅 후 소멸):**
```bash
# <bridge>는 docker network inspect <net> | grep "br-"로 확인
iptables -I FORWARD -i br-<id> -o br-<id> -j ACCEPT
```

**방법 2 (영구):**
```bash
# iptables-persistent 또는 /etc/iptables/rules.v4에 위 규칙 추가
```

**방법 3 (실용적 대안):**
```bash
# 모든 컨테이너를 --network host로 통일
# nginx가 localhost:<port>로 프록시
docker run -d --network host ...
```

## 주의

- `--network host`는 컨테이너가 호스트 네트워크를 그대로 사용 → 포트 충돌 주의
- nginx는 `--network host`면 `localhost:앱포트`로 프록시 가능
- 앱 컨테이너 포트가 겹치지 않도록 각각 다른 포트 사용
