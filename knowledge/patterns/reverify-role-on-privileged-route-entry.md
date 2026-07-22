---
type: pattern
tags: [auth, rbac, react, session-cache]
---

# 권한 라우트 진입 시 서버 재검증 — 로그인 시점 캐시만 믿지 않기

## 문제

클라이언트가 로그인 시점에 사용자의 role/권한 정보를 한 번 fetch해서
`localStorage`(또는 메모리)에 캐싱하고, 이후 모든 UI 게이팅을 그 캐시만 보고
판단하는 패턴은 흔하다. 문제는 **세션 도중 서버 쪽 권한이 바뀌는 경우** —
관리자가 이 사용자에게 새 역할을 부여하거나 회수하는 경우 — 클라이언트가
재로그인 전까지 그 변화를 절대 알 수 없다는 것이다.

증상: "방금 권한을 줬는데 그 사용자한테는 메뉴가 안 보인다" /
"권한을 뺏었는데 계속 접근된다(다음 API 호출에서야 403으로 막힘)".

## 해결 패턴

권한이 걸린 라우트/레이아웃에 진입할 때마다, 캐시된 값으로 즉시 판단하지 말고
서버에 최신 상태를 한 번 물어본 뒤 판단한다.

```tsx
// 레이아웃 레벨에서 진입 시마다 재검증
const { isLoading, refreshRole } = useAuth()
const [checked, setChecked] = useState(false)

useEffect(() => {
  if (isLoading) return
  refreshRole().finally(() => setChecked(true))
}, [isLoading, refreshRole])

useEffect(() => {
  if (!checked) return
  if (!hasAccess) router.push('/')
}, [checked, hasAccess, router])

if (isLoading || !checked) return <Spinner />
```

`refreshRole()`은:
1. 저장된 토큰으로 `/me` 같은 "내 정보" 엔드포인트를 다시 호출
2. 응답으로 로컬 캐시(`localStorage` 등)를 갱신
3. 커스텀 DOM 이벤트(예: `auth-role-changed`)를 쏴서, 같은 훅을 쓰는 다른
   컴포넌트 인스턴스(사이드바 등)도 함께 갱신되도록 함 — React context가 아니라
   훅+로컬 state 조합이라 인스턴스 간 동기화가 필요할 때 특히 중요

## 언제 적용하나

- 관리자 페이지, 역할 기반 기능 진입점 등 "권한이 걸린 화면"의 최상위 레이아웃/가드
- 매 페이지 이동마다는 과도할 수 있음 — **레이아웃 레벨 1곳**에서 한 번만 재검증하면
  하위 페이지들은 이미 최신 상태를 물려받음
- 진짜 보안 경계는 항상 서버(API 호출 시 인가 체크)에 있어야 함 — 이 패턴은 UX
  개선(불필요한 튕김/숨겨진 버튼 방지)이지 보안 대체재가 아님

## 놓치기 쉬운 함정

새 역할/권한 플래그를 추가할 때 **라우트 가드 하나만 고치고 끝내기 쉽다.**
그 역할로 가는 진입점이 여러 곳(사이드바 버튼, 메뉴 항목, 딥링크 등)에 흩어져
있다면, 기존 역할(예: `isAdmin`)의 모든 사용처를 grep해서 새 역할도 함께
반영해야 하는지 하나하나 판단해야 한다. 그렇지 않으면 "가드는 맞게 짰는데
애초에 들어갈 방법이 없다"는 사각지대가 생긴다.

## 관련 페이지

- [[projects/dna-sql-agent-web/issues/group-admin-entry-point-missing|group-admin-entry-point-missing]] (이 패턴을 도출한 실제 사례)
