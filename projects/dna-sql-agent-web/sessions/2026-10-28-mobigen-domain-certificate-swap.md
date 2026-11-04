---
type: session-log
project: dna-sql-agent-web
date: 2026-10-28
duration: 
focus: "mobigen 서버 도메인 연결 — 공인 인증서 적용"
tools-used: [claude-code]
outcome: success
---

# 2026-10-28 — mobigen 서버 도메인 연결, 공인 인증서 적용

## 목표

dev 서버(이후 mobigen 서버로 부름)에 도메인이 연결되어 받은 공인 인증서를 nginx에 적용.

## 수행한 작업

1. dev 워크플로우·nginx.conf 확인 (linko·monaco와 마운트 경로 동일) — 인증서는 `/home/dnadev/ca` → `/etc/nginx/certs` 마운트, `server.crt`/`server.key` 고정 참조
2. 기존 `ca.crt`·`ca.key` 정체 확인 — ADR-005의 사설 CA, nginx 미사용
3. 새 인증서를 `/home/dnadev/ca/server.crt`(fullchain)·`server.key`로 교체 후 nginx reload (사용자가 서버에서 직접 수행)

## 핵심 결정

- **볼륨 매핑 변경 대신 파일만 교체:** nginx.conf를 linko·monaco와 공유하므로 경로 변경 시 다른 서버 nginx 기동 실패 위험.
  파일 교체는 워크플로우 재실행 불필요
  → ADR: [[decisions/020-mobigen-domain-public-cert-file-swap]]

## 배운 것

- 볼륨(`-v`)은 컨테이너 생성 시 고정 — `docker restart`로는 반영 안 되고 rm 후 재생성 필요.
  이 프로젝트는 워크플로우가 nginx를 매번 재생성하므로 서버에서 수동 변경해도 다음 배포에 덮어써짐
- nginx는 인증서 파일 이름·확장자 무관, PEM 내용만 읽음
- Let's Encrypt `live/` 파일은 `archive/` 심볼릭 링크 — 마운트 시 `/etc/letsencrypt` 전체 필요
- nginx 담당 워크플로우는 web 쪽뿐, 백엔드(dna-sql-agent) 워크플로우는 nginx를 건드리지 않음

## 다음 할 일

- [ ] ADR-020 서버 정보 TODO 채우기 (도메인, IP, 발급처, 만료일)
- [ ] 인증서 만료일 캘린더 등록
- [ ] `ca-old/`의 사설 CA를 다른 서비스가 참조하는지 확인 후 정리
