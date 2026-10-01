---
type: troubleshooting
tags: [network, vpn, ssh, macos]
created: 2026-08-28
updated: 2026-08-28
---

# VPN 은 붙었는데 사내 서버에 못 갈 때 — 서브넷 충돌

## 증상

- VPN 클라이언트는 "연결됨" 인데 사내 서버로 `ping` 이 전부 timeout
- `ssh -v` 가 `debug1: Connecting to ...` 에서 멈춘다 (`Connection refused` 가 아니라 **멈춤**)
- **휴대폰 핫스팟으로 바꾸면 정상 접속된다** ← 결정적 단서

`refused` 는 서버가 살아있고 포트만 닫힌 것이고, **멈춤은 패킷이 조용히 버려지는 것**이다.

## 판별 (macOS)

```bash
ifconfig en0 | grep "inet "        # 로컬 LAN 대역
ifconfig | grep -A2 "^utun"        # VPN 터널 대역
netstat -rn -f inet | head -20
route -n get <서버IP>              # interface 가 utun 인지 en0 인지
```

`route get` 의 `interface` 가 **`utun` 이 아니라 `en0`** 로 나오면 확정이다.
VPN 이 내려준 DNS 서버조차 `en0` 로 나가는 것을 보면 더 확실하다.

## 원인

**VPN 이 할당한 대역과 지금 접속한 네트워크의 대역이 겹치면**, 커널은 그 대역으로
가는 패킷을 로컬 링크(en0)로 보낸다. 로컬 랜에 그 서버는 없으니 응답 없이 버려진다.

```
en0   (로컬 LAN):  172.16.0.230/23
utun4 (VPN 터널):  172.16.0.4/23     ← 같은 172.16.0.0/23
```

이 상태에서는 터널이 UP 이어도 **그 안으로 들어가는 트래픽이 하나도 없다.**
`utun` 으로 가는 라우트가 자기 IP 하나뿐인 것으로 확인된다.

VPN 클라이언트 설정을 아무리 만져도 해결되지 않는다. 라우팅 우선순위 문제다.

## 해결

1. **다른 네트워크로** — 핫스팟(보통 `172.20.10.x`)은 충돌하지 않는다. 즉시 확인용
2. **공유기 LAN 대역 변경** — 집이나 직접 관리하는 공유기면 `192.168.50.0/24` 등으로
3. **VPN 할당 풀 변경 요청** — 사무실 네트워크면 이쪽이 정공법
4. **임시 우회** — 특정 서버 하나만 급할 때
   ```bash
   sudo route add -host <서버IP> -interface utun4
   route -n get <서버IP>          # interface 가 utun 으로 바뀌었는지
   ```
   재연결·재부팅 시 사라지고, 그 IP 와 겹치는 로컬 기기가 있으면 그쪽 통신이 끊긴다

## 함정

- **VPN 클라이언트를 두 개 이상 동시에 띄우면** 서로 라우팅을 덮어써서 충돌이 없어도
  같은 증상이 난다. 안 쓰는 쪽은 완전히 종료한다
- **`ping` 이 안 된다고 접속이 안 되는 것은 아니다.** 보안 정책으로 ICMP 만 막아둔
  서버가 많다. 접속 확인은 `nc -zv -w 5 <IP> 22` 로 한다
- macOS 는 `telnet` 이 기본 제공되지 않는다. `nc` 로 대체한다

## 관련 페이지

- [[projects/dna-sql-agent-deploy/sessions/2026-08-28-rootless-docker-vfs-closed-network-deploy|2026-08-28 세션]]
