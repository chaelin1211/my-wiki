---
type: knowledge
tags: [nextjs, basepath, docker, deployment]
created: 2026-10-16
updated: 2026-10-16
---

# Next.js basePath 를 런타임에 정하기

Next `basePath` 는 빌드 타임 값이다. `NEXT_PUBLIC_*` 처럼 결과물(HTML·JS·manifest)에 문자열로
박히고, 공식 런타임 지정 방법은 없다. 이미지 한 벌로 배포처마다 다른 경로를 쓰려면 치환밖에 없다.

## 자리표시자 치환 패턴

1. 빌드할 때 아무도 안 쓸 고유 문자열로 지정: `basePath: '/__APP_BASE_PATH__'`
   - `/` 로 빌드하면 안 됨 — 어느 `/` 가 basePath 자리인지 구분 불가
2. 컨테이너 entrypoint 가 기동 시 `server.js`·`.next/` 안의 자리표시자를 환경변수 값으로 바꾼 뒤
   `exec node server.js`
3. 빈 값으로 치환하면 `/` 로 빌드한 것과 같은 결과

주의점:
- manifest 의 정규식에는 escape 된 형태로 들어갈 수 있음 → `\\/`·`\/`·`%2F`·`/` 접두 모두 치환
  (긴 것부터). 값 쪽 `/` 도 같은 형태로 바꿔 넣기
- 치환 후 자리표시자가 남으면 **기동을 멈추게** 해서 조용히 깨지지 않게 할 것
- sed 보다 node 로 처리하는 편이 백슬래시 다루기 쉬움(이미지에 node 가 이미 있음).
  제자리 덮어쓰기면 디렉터리 쓰기 권한 불필요
- Docker `ENV` 가 `.env.production` 보다 우선 → 빌드 단계 `ENV` 로 자리표시자를 넣으면 `.env.production` 의
  같은 키는 무시됨
- standalone 결과물에는 `.env.production` 이 복사되지만 읽는 건 `server.js` 이지 그보다 먼저 도는
  entrypoint 가 아님

## basePath 가 자동으로 붙는 곳 / 안 붙는 곳

| 자동 | 수동(`withBasePath()` 등으로 감싸야 함) |
|------|------|
| `<Link href>`, `router.push/replace`, 서버 `redirect()` | `fetch('/...')`, `EventSource`, `window.open('/...')` |
| `/_next/static/*` 청크·CSS | `next/image` `src="/logo.png"` (`unoptimized` 포함) |
| | metadata `icons` URL, `<a href="/">` 원시 태그 |

API 를 상대경로로 부르는 경우 API base URL 도 basePath 와 같은 값으로 맞춰야 함.

## 로컬 확인

- `.env.development` 에 `NEXT_PUBLIC_BASE_PATH=/x` → dev 서버 재시작 → `localhost:3000/x`
  (`/` 는 404 가 정상)

## 관련

- [[projects/dna-sql-agent-web/decisions/019-runtime-base-path-placeholder-substitution|ADR-019]]
- [[knowledge/tools/nginx-docker-envsubst-templates]]
