---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-08-28
resolved: false
root-cause: "useIsOfficeAddin 이 load 이벤트만 듣고 error 를 듣지 않아, 외부 office.js 가 로드되지 않는 폐쇄망에서 판정이 null 로 남는다"
related: [office-addin, closed-network, deployment]
tags: [nextjs, react, office-addin, offline, deployment]
---

# 폐쇄망에서 관리자·대시보드 버튼이 안 뜬다

## 증상

로그인은 성공하고 DB 상 그룹도 `admin` 인데 사이드바에 관리자 버튼이 나타나지 않는다.
에러 메시지는 아무것도 없다.

```
dna-sql-agent | INFO: 172.19.0.6:37090 - "POST /api/v1/auth/login HTTP/1.0" 200 OK
```

```sql
SELECT u.email, g.name FROM users u JOIN groups g ON g.id=u.group_id;
--  admin@dadap.local | admin
```

`/admin` 으로 직접 들어가면 정상 동작한다. 버튼만 없다.

## 환경

- **런타임:** Next.js standalone, 컨테이너 배포
- **재현 조건:** **외부 인터넷이 차단된 망**. 사내망·개발 환경에서는 재현되지 않는다

## 게이팅 조건

`components/sidebar-user-menu.tsx:38`

```tsx
{showAdminButton && (isAdmin || isGroupAdmin) && isOfficeAddin === false && (
```

조건이 셋이고, 세 번째가 폐쇄망에서 막힌다.

`hooks/use-office-addin.ts:3` 의 반환 타입은 **`boolean | null`** 이고 초기값이 `null` 이다.
`null` 은 `=== false` 가 아니므로 **판정이 끝나지 않으면 버튼이 숨겨진다.**

```ts
const script = document.querySelector('script[src*="office.js"]')
if (script) {
  script.addEventListener('load', detect, { once: true })   // load 만 듣는다
} else {
  setIsAddin(false)
}
```

그리고 그 스크립트는 외부다 — `app/layout.tsx:65`

```tsx
<Script src="https://appsforoffice.microsoft.com/lib/1/hosted/office.js" strategy="afterInteractive" />
```

```
폐쇄망 → office.js 로드 실패 → error 는 나지만 아무도 안 듣는다
     → isAddin 이 null 로 고정
     → isOfficeAddin === false 가 false
     → 버튼 숨김
```

`isAdmin` 이 `true` 여도 소용없다.

## 같은 조건을 쓰는 다른 곳

- `components/conversation-list.tsx:240` — 대시보드 열기 버튼. 같이 사라진다

## 시도한 것들

1. ❌ **재로그인·localStorage 초기화** — `jwt_auth` 의 `group` 은 정상적으로 `admin` 이었다.
   `use-auth.ts:148` 의 `isAdmin: group === 'admin'` 도 `true`
2. ❌ **강력 새로고침** — localStorage 를 비우지 않으며, 애초에 원인이 아니었다
3. ✅ **게이팅 조건 확인** — 세 번째 조건 `isOfficeAddin === false` 에서 막히는 것 확인

## 진단

브라우저 콘솔:

```js
document.querySelector('script[src*="office.js"]')     // 태그 존재 여부
JSON.parse(localStorage.getItem('jwt_auth')).group     // 'admin' 인지
```

Network 탭에서 `office.js` 가 `failed` / `pending` 으로 남아 있으면 확정이다.

## 해결 방법

**미적용.** `hooks/use-office-addin.ts:27`

```ts
if (script) {
  script.addEventListener('load', detect, { once: true })
  // 폐쇄망에서는 office.js 를 받을 수 없다. error 를 듣지 않으면 판정이 끝나지
  // 않아 null 로 남고, isOfficeAddin === false 로 게이팅된 관리자·대시보드
  // 버튼이 조용히 사라진다.
  script.addEventListener('error', () => { if (active) setIsAddin(false) }, { once: true })
} else {
  setIsAddin(false)
}
```

응답 없이 매달리는 경우(DNS 타임아웃)까지 막으려면 타임아웃도 같이 둔다.

```ts
const timer = setTimeout(() => {
  if (active) setIsAddin((v) => (v === null ? false : v))
}, 3000)
return () => { active = false; clearTimeout(timer) }
```

**우회 (수정 전까지):** 주소창에 `/admin` 직접 입력.
`app/admin/layout.tsx:37` 은 `isAdmin || isGroupAdmin` 만 보고 `isOfficeAddin` 은 안 본다.

## 예방책

- **`null` 을 "판정 중" 으로 쓰는 상태는 UI 게이팅에 직접 넣지 않는다.**
  `=== false` 비교는 로딩 중과 부정을 같은 취급으로 만든다. 게이팅에는
  `!isOfficeAddin` 처럼 `null` 을 부정으로 흡수하는 형태를 쓰거나,
  판정 완료 여부를 별도 플래그로 분리한다
- **외부 CDN 의존은 폐쇄망 납품에서 항상 실패 지점이 된다.** `app/layout.tsx` 의
  외부 스크립트는 로드 실패를 전제로 폴백 경로를 갖춰야 한다
- `useIsOfficeExcel`(`use-office-addin.ts:59`)은 초기값이 `false` 라 같은 문제가 없다.
  두 훅의 초기값이 다른 것 자체가 함정이다

## 관련 페이지

- [[bookmark-header-missing-office-addin-check]]
- [[projects/dna-sql-agent-deploy/sessions/2026-08-28-rootless-docker-vfs-closed-network-deploy|2026-08-28 세션]]
