---
type: session-log
project: dna-sql-agent, dna-sql-agent-web
date: 2026-06-17
duration: ~3h
focus: "PPT 애드인 HTTP 지원 — nginx 28001 포트 추가 & Docker 네트워크 구조 탐색"
tools-used: [claude-code]
outcome: partial (HTTP 28001 적용 완료, Docker 네트워크 방식은 서버 방화벽으로 롤백)
---

# 2026-06-17 — PPT 애드인 HTTP 지원 & nginx 포트 구성

## 목표

- PPT Office 애드인이 `http://서버IP:28001`로 웹 접근 가능하도록 nginx 설정
- Docker 컨테이너 구조를 `--network host`에서 Docker 커스텀 네트워크로 개선 시도
- Next.js Dockerfile 포트 28001 → 3000 변경

## 수행한 작업

1. Dockerfile `EXPOSE/PORT` 28001 → 3000 변경
2. nginx.conf에 HTTP 28001 서버 블록 추가 (`/api|health` + `/` 모두 프록시)
3. nginx HTTPS 블록 프록시 대상 `localhost:28001` → `localhost:3000` 수정
4. 워크플로우(dev/mobigen) Next.js 컨테이너 `--publish 3000:3000` 또는 `--network host` 정리
5. Docker 커스텀 네트워크(dna-net) 기반 구조 시도 — 컨테이너 이름으로 통신
6. 서버 iptables FORWARD DROP으로 컨테이너 간 ping조차 안 됨 → `--network host`로 전면 롤백
7. 백엔드 워크플로우(dev/mobigen)도 `--network host` 통일

## 핵심 결정

- **nginx가 HTTP 28001도 리슨**: 애드인이 웹 UI를 브라우저처럼 로드하고, 앱 내부에서 `/api/*` 호출이 발생 → nginx가 same-origin으로 처리해야 CORS 없음
  → ADR: [[projects/dna-sql-agent-web/decisions/015-http-addin-nginx-28001]]

- **Docker 커스텀 네트워크 포기**: 서버 방화벽이 FORWARD 체인을 DROP → 컨테이너 간 IP 통신 불가. `--network host`가 이 환경에서 유일한 실용 선택.
  → 이슈: [[projects/dna-sql-agent/issues/docker-custom-network-forward-drop]]

## 배운 것

- PPT 애드인 webview: 페이지 origin과 API 호출 origin이 같아야 CORS 없음 → nginx가 HTTP/HTTPS 포트 모두에서 `/api/*`를 프록시해야 함
- Docker 커스텀 네트워크는 서버 iptables FORWARD 정책에 의존. `--network host`는 비표준이지만 엄격한 방화벽 환경에서 사실상 대안 없음
- `wget localhost:3000` → IPv6 `[::1]`로 붙음. Alpine 컨테이너에서는 `wget 127.0.0.1:3000`으로 명시해야 함

## 문제 & 해결

- **문제:** Docker 커스텀 네트워크에서 nginx → Next.js 컨테이너 ping 100% 패킷 손실
- **원인:** 서버 iptables FORWARD 체인 DROP 정책
- **해결:** `--network host` 롤백
  → 이슈: [[issues/docker-custom-network-forward-drop]]

- **문제:** `wget localhost:3000` connection refused인데 `/proc/net/tcp`는 0.0.0.0:3000 LISTEN
- **원인:** Alpine wget이 localhost를 IPv6 `[::1]`로 해석, Next.js는 IPv4만 바인딩
- **해결:** `wget 127.0.0.1:3000` 명시

## 다음 할 일

- [ ] 배포 검증 완료 후 워크플로우 ref를 `main`으로 되돌리기
- [ ] CORS 설정 재검토 (nginx same-origin이면 불필요하나 확인 필요)
- [ ] 대시보드 PR 생성 및 머지
