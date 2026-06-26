---
type: decision-record
project: dna-sql-agent-web
date: 2026-06-17
status: accepted
superseded-by: ""
tags: [nginx, deployment, ppt-addin, http]
---

# ADR-015: nginx HTTP 28001 포트로 PPT 애드인 지원

## 맥락

PPT Office 애드인이 웹 UI를 webview(브라우저처럼)로 로드해야 한다. 기존 구조는 HTTPS(443)만 서빙했으나, 애드인 환경에서 HTTPS를 요구하지 않고 `http://서버IP:28001`로 접근해야 하는 요구가 생겼다.

단순히 28001을 443으로 리다이렉트하면 안 됨 — 애드인 webview 내 Next.js 앱이 `/api/*`를 호출할 때 same-origin이어야 CORS 없이 동작한다.

## 선택지

### 옵션 A: 28001 → HTTPS 301 리다이렉트
- **장점:** 구현 단순
- **단점:** 브라우저 URL이 HTTPS로 바뀜. 애드인 환경에 따라 혼합 콘텐츠(mixed content) 문제 발생 가능
- **비용/노력:** 낮음

### 옵션 B: nginx에서 HTTP 28001도 완전 프록시 (api + 프론트)
- **장점:** same-origin 유지 → CORS 없음. 애드인 webview에서 완전 동작
- **단점:** HTTP 평문 전송
- **비용/노력:** 낮음 (nginx 서버 블록 추가)

### 옵션 C: Next.js rewrites로 `/api/*` 서버사이드 프록시
- **장점:** nginx 불필요
- **단점:** Next.js 설정 복잡, 백엔드 URL을 빌드 타임에 알아야 함
- **비용/노력:** 중간

## 결정

**옵션 B를 선택한다.**

nginx에 `listen 28001` 서버 블록을 추가하고, `/api|health`는 백엔드(localhost:28000)로, `/`는 Next.js(localhost:3000)로 프록시한다.

## 근거

애드인 webview는 페이지 origin(`http://서버IP:28001`)과 API 호출 origin이 동일해야 한다. nginx가 같은 포트에서 프론트엔드와 백엔드 API를 모두 처리하면 same-origin이 자동으로 보장된다. HTTP 평문 전송은 내부망 용도이므로 허용 가능.

## 결과

- `http://서버IP:28001` → nginx → Next.js + 백엔드 API (same-origin)
- `https://서버IP` → nginx → Next.js + 백엔드 API (same-origin, HTTPS)
- `http://서버IP:80` → 301 redirect to HTTPS
- Next.js 컨테이너 포트를 28001 → 3000으로 변경 (nginx가 28001 소유)

## 참고 자료

- [[projects/dna-sql-agent-web/decisions/014-multi-server-nginx-reverse-proxy]]
