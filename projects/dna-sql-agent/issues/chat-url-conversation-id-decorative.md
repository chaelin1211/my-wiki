---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-07-31
resolved: true
root-cause: "인증 토큰이 localStorage 에 있어 Next.js 서버가 대화를 조회할 수 없고, 렌더링이 layout 으로 올라가 URL 이 상태에서 파생되기만 함"
related: []
tags: [frontend, routing, nextjs, auth]
---

# `/chat/[id]` 의 conversation_id 가 실제로 동작하지 않던 문제

## 증상

`/chat/{아무 문자열}` 로 진입해도 아무 일도 일어나지 않았다. 에러도 리다이렉트도
없이 이전에 열려 있던 대화가 그대로 보이고, URL 에는 엉뚱한 id 가 남았다.
새로고침이나 URL 붙여넣기로 특정 대화를 여는 것(콜드 진입 딥링크)도 동작하지 않았다.

## 환경

- `dna-sql-agent-web`
- `app/(app)/layout.tsx` — URL↔상태 동기화 effect 2개
- `app/(app)/chat/[id]/page.tsx` — `return null` 껍데기

## 근본 원인

두 가지가 겹쳐 있었다.

**1. 서버가 대화를 조회할 수 없다.**
JWT 를 `localStorage['jwt_auth']` 에 저장하고 `Authorization: Bearer` 헤더로 보내는
구조라(`lib/fetch-client.ts`), Next.js 서버는 요청자가 누구인지 알 수 없다. 게다가
백엔드가 별도 서버(`:8000`)다. 그래서 서버 컴포넌트가 할 일이 없고
`[id]/page.tsx` 는 `return null` 이 되었다.

**2. 렌더링이 layout 으로 올라가 있었다.**
`a00abbc` "Next.js 라우트 기반 네비게이션 구조로 전환"(2026-06-09)에서 **대화 전환 시
페이지 컴포넌트 remount 로 인한 깜빡임을 없애려고** ChatView 를 layout 에서 직접
렌더하고 상태를 Context 로 올렸다. 그 결과 화면은 상태가 그리고 URL 은 뒤따라
갱신되기만 하는 구조가 되었다.

동기화가 반쪽으로 남은 것이 증상의 직접 원인:

| 방향 | 상태 |
|---|---|
| 상태 → URL | `pathname === '/chat'` 일 때만 `replace` — 조건이 좁아 잘못된 id 를 못 고침 |
| URL → 상태 | 의존성이 `[pathname]` 뿐이고 목록은 ref 라 재실행되지 않음 — 콜드 진입 시 목록 로드 전 early return 후 끝 |

## 해결 방법

**`/chat/[id]` 라우트를 제거했다** (`0325bac`). 라우트 파일 삭제, 동기화 effect 2개
제거, 대화 이동 경로를 모두 `/chat` 으로 통일.

앞서 클라이언트에서 해결하려 시도했으나 모두 되돌렸다:

1. 로컬 목록으로 존재 확인 → 목록 로드 순서에 의존, 페이지네이션 밖 대화는 오판
2. 서버 조회로 전환 → 초기 목록 로드가 목록을 통째로 교체(`return backendConvs`)해
   삽입한 대화가 사라짐
3. effect 의존성에 목록 추가 → 조회가 목록을 바꾸고 목록 변화가 effect 를 다시 태우는
   **순환 발생, 무한 깜빡임**
4. 목록 밖 별도 슬롯(detached) 보관 → 전송 시 승격 필요, 엣지 케이스 다수

근본 제약(서버가 인증할 수 없음)을 클라이언트에서 우회하려니 복잡도만 늘었다.

## 재도입 조건

**세션(httpOnly 쿠키) 인증으로 전환한 뒤**가 정석 경로다. 쿠키는 요청마다 자동 전송되므로
Next.js 서버가 사용자를 인증할 수 있고, 그때는 원래 기대하던 흐름이 가능해진다:

```
GET /chat/{id} (쿠키 포함)
  → 서버가 백엔드 조회
      없음 → notFound()
      있음 → 대화가 그려진 화면을 응답
```

주의: 채팅 SSE 스트리밍은 여전히 브라우저가 해야 하고, 깜빡임 방지를 위해
layout 에서 렌더하는 구조도 재검토가 필요하다.

## 잃은 것

- 대화 링크 공유
- 브라우저 뒤로가기로 대화 전환 (제거 전에는 동작했다)

## 예방책

- URL 을 라우팅 수단으로 쓸지 상태 파생물로 쓸지 먼저 정할 것. 어중간하면
  "동작하는 것처럼 보이지만 콜드 진입은 깨진" 상태가 된다
- 인증 방식(localStorage vs 쿠키)이 서버 렌더링 가능 범위를 결정한다는 점을
  라우팅 설계 시점에 고려할 것
- effect 의존성에 그 effect 가 변경하는 상태를 넣지 말 것 — 순환이 된다

## 관련 페이지

- [[decisions/029-conversation-system-scope-server-side]]
