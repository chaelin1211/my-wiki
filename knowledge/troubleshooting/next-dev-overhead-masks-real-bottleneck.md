---
type: troubleshooting
tags: [nextjs, dev-server, turbopack, performance, diagnosis]
---

# "느려 보인다"는 체감 보고는 API 시간보다 dev/prod 여부부터 확인

## 문제 패턴

Next.js 앱에서 특정 화면(예: 채팅 목록 로딩)이 느리다는 보고를 받고 API 응답 시간을 재보면
정작 수십~수백 ms로 정상인데도, 사용자는 계속 느리다고 체감하는 경우가 있다.

## 원인

`next dev`(특히 Turbopack 개발 서버)는 프로덕션 빌드 대비 페이지 `load` 이벤트가 몇 배 느릴 수 있다:

- 번들이 minify/tree-shaking 안 됨
- HMR(핫 리로드) 클라이언트, devtools 스크립트가 포함됨
- 코드 스플리팅이 dev 모드에선 최적화가 덜 됨
- 라우트별 온디맨드 컴파일 (첫 진입 시 추가 지연)

실측 예 (dna-sql-agent-web, `next dev`, 2026-07-24): 개별 API(`/systems`, `/connections`, `/chat/...`)는
모두 60~230ms인데 `performance.getEntriesByType('navigation')[0].loadEventEnd`는 2500~2900ms.
즉 체감 지연의 대부분이 API가 아니라 JS 번들 다운로드/파싱/실행 시간이었다.

## 진단 순서

1. 브라우저 콘솔에서 실제 리소스 타이밍을 직접 잰다:
   ```js
   performance.getEntriesByType('resource')
     .filter(e => e.name.includes('/api/'))
     .map(e => ({ name: e.name, start: Math.round(e.startTime), duration: Math.round(e.duration) }))
   ```
   API 호출들이 이미 빠르면(수십~수백 ms), API 자체는 범인이 아니다.
2. `performance.getEntriesByType('navigation')[0]`의 `loadEventEnd`/`domContentLoadedEventEnd`를 확인한다.
   API 총 시간보다 훨씬 크면 번들 로딩/실행 쪽을 의심한다.
3. `next build && next start`(프로덕션 빌드)로 같은 페이지를 다시 재고, 위 숫자가 확 줄어드는지 비교한다.
   줄어들면 dev 서버 오버헤드가 원인이었다는 뜻 — 코드 최적화보다 "지금 보고 있는 게 dev냐 prod냐"부터 사용자에게 확인시켜야 한다.

## 예방책

- 성능 이슈를 처음 접수하면, 코드 뜯어보기 전에 **dev 서버로 보고 있는지부터** 물어본다
- VS Code `launch.json`에 `npm run build && npm run start` 실행 설정을 미리 추가해두면
  프로덕션 비교가 한 번의 클릭으로 가능해져 진단이 빨라진다

## 관련 페이지

- [[projects/dna-sql-agent-web/sessions/2026-07-24-sql-block-render-perf-and-conversation-loading]]
