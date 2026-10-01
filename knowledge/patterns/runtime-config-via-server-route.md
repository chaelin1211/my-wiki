---
type: pattern
tags: [deployment, config, offline, nextjs, docker]
created: 2026-08-25
---

# 배포처마다 다른 화면 설정은 빌드가 아니라 서버 라우트에서 읽는다

## 문제

프론트엔드 프레임워크의 "공개 환경변수"(Next.js `NEXT_PUBLIC_*`, Vite `VITE_*`, CRA `REACT_APP_*`)는 **빌드 시점에 코드에 박힌다.** 번들에 문자열로 치환되므로 실행 시점의 환경변수는 아무 영향이 없다.

이미지 안에서 빌드가 도는 구성이라면 결과가 이렇게 된다.

- 값을 바꾸려면 **이미지를 다시 만들어야 한다**
- 고객사마다 다른 값이 필요하면 **고객사 수만큼 이미지가 갈라진다**
- 배포 담당자가 `docker run -e` 나 `.env` 로 값을 줘도 조용히 무시된다. 에러가 없어 원인을 찾기 어렵다

특히 폐쇄망 납품처럼 "산출물은 한 벌, 설정만 현장에서" 가 전제인 배포에서 정면으로 어긋난다.

## 해결

**서버가 요청 시점에 `process.env` 를 읽어 내려주는 라우트를 하나 두고, 화면이 그것을 받아 쓴다.**

```ts
// app/map-config/route.ts
export const dynamic = 'force-dynamic'   // 빌드 타임 프리렌더 방지 — 이게 핵심

export function GET(): Response {
  const url = process.env.MAP_TILE_URL?.trim() || undefined
  return Response.json(resolve(url), { headers: { 'Cache-Control': 'no-store' } })
}
```

```ts
// 클라이언트: 모듈 단위로 한 번만 받아 캐시하고, 실패하면 기본값으로 그린다
let pending: Promise<Settings> | null = null
function load() {
  if (!pending) pending = fetch('/config').then(r => r.json()).catch(() => DEFAULTS)
  return pending
}
```

## 주의할 점

- **`force-dynamic` 을 빠뜨리면 의미가 없다.** 라우트가 정적 프리렌더되면 빌드 시점 값이 그대로 굳는다. 빌드 로그에서 그 라우트가 동적(`ƒ`)으로 잡혔는지 확인한다.
- **기본값을 반드시 둔다.** 설정을 안 준 배포는 종전대로 동작해야 하고, 조회 실패도 화면을 깨뜨리면 안 된다.
- **받아오기 전 한 프레임은 기본값으로 그려진다.** 이 지연이 허용되지 않는 값(테마 플래시 등)에는 맞지 않는다.
- **컨테이너 env 가 파일보다 우선한다.** Next.js standalone 은 `.env.production` 을 런타임에도 읽지만, `@next/env` 는 이미 설정된 `process.env` 를 덮지 않는다. `docker run -e` 가 이긴다.
- **개발 서버는 `.env.production` 을 읽지 않는다.** dev 는 `.env.development`·`.env.local` 만 본다. 로컬에서 확인할 때 자주 걸린다.
- 기존 `NEXT_PUBLIC_*` 값을 폴백으로 함께 읽으면 이전 배포와 호환된다.

## 어디까지 이 방식이고, 어디부터 설정 API 인가

운영 중 관리자가 바꿔야 하고 이력·권한이 필요한 값이면 백엔드 설정 API 로 가는 편이 맞다. 이 패턴은 **설치 시점에 한 번 정하고 이후 거의 바뀌지 않는 값**에 쓴다 — 외부 서비스 주소, 타일 서버, 기능 토글 같은 것. `.env` 에 이미 DB 주소·포트가 있다면 그 옆에 두는 것이 설치 절차와 일치한다.

## 참고

- [[projects/dna-sql-agent/decisions/039-runtime-config-via-server-route]]
