---
date: 2026-06-16
type: session-log
project: dna-sql-agent-web, dna-sql-agent
tags: [deployment, nginx, cors, docker, multi-server]
---

# 2026-06-16 다중 서버 배포 설정

## 작업 배경

기존에 `.env.production`에 IP가 하드코딩되어 있어 단일 서버에만 배포 가능했음. 신규 서버 추가 배포를 위해 구조 개선.

## 작업 내용

### 프론트 (dna-sql-agent-web) — `feat/multi-server-nginx-proxy`

- `.env.production`: `NEXT_PUBLIC_API_BASE_URL` 빈 값으로 변경 (IP 하드코딩 제거)
- `nginx.conf`: `/api`, `/health` 요청을 백엔드(`localhost:28000`)로 프록시하는 정규식 location 추가
- `dna-sql-agent-web_mobigen.yml`: 웹 컨테이너 `--network host` → `--publish 28001:28001` 변경

### 백엔드 (dna-sql-agent) — `feat/cors-config`

- `src/dna/settings/defaults/cors.json`: CORS 기본값 파일 생성 (서버 IP 제거, localhost/addin만 허용)
- `src/dna/settings/manager.py`: SECTIONS에 `"cors"` 추가
- `src/main.py`: 하드코딩된 CORS origins → `settings_manager.load("cors")`로 교체

## 핵심 결정

- nginx 리버스 프록시 방식 채택 → 이미지 하나로 모든 서버 배포 가능
- CORS는 nginx 프록시로 same-origin 처리 → 서버 IP 별도 설정 불필요
- 각 서버 CORS 설정은 `/home/dnadev/config/cors.json` 수기 1회 작성

## 신규 서버 세팅 절차

1. Docker 설치
2. SSL 인증서: 기존 `ca.key`, `ca.crt` 복사 후 신규 서버 IP로 `server.crt`, `server.key` 발급
3. GitHub Actions Runner 등록 (`--labels` 로 서버 구분)
4. `/home/dnadev/config/cors.json` 작성

## 미해결

- dev 서버에서 `--publish` 불가한 원인 미파악 (방화벽 가능성)
- Docker bridge network로의 전환 검토 필요 (현재 nginx `--network host` 유지)

## 관련 ADR

- [[014-multi-server-nginx-reverse-proxy]]
- [[005-https-internal-ca-nginx]]
