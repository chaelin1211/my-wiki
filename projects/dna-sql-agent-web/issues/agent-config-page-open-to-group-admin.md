---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-08-13
resolved: false
root-cause: "/admin/* 레이아웃이 그룹 관리자까지 통과시키는데 에이전트 설정 화면에는 자체 판단이 없다"
related: [admin, settings]
tags: [frontend, permissions]
---

# 그룹 관리자가 URL로 에이전트 설정 화면에 들어갈 수 있다

## 증상

그룹 관리자 계정으로 `/admin/agent-config` 주소를 직접 치면 화면이 열린다. 사이드바에 메뉴는 보이지 않는다.

서버 설정 API 가 관리자 전용으로 바뀐 뒤로는 화면이 열린 채 항목마다 403 오류가 뜬다. 그 전에는 값을 읽고 고칠 수도 있었다.

## 근본 원인

`app/admin/layout.tsx` 가 시스템 관리자와 그룹 관리자를 모두 통과시키고, 어떤 화면을 볼 수 있는지는 각 페이지가 판단하는 구조다. `app/admin/agent-config/page.tsx` 에 그 판단이 없다.

## 해결 방법 (미적용)

페이지에서 관리자가 아니면 되돌린다.

```tsx
const { isAdmin } = useAuth()
useEffect(() => { if (!isAdmin) router.push('/') }, [isAdmin, router])
```

서버가 이미 막고 있어 보안 문제는 아니다. 오류가 깔린 화면 대신 되돌려 보내는 것이 목적이다.

## 관련 페이지

- 서버 PR: DnA-Platform-Development-Team/dna-sql-agent#140 (설정 API 관리자 전용화)
- [[projects/dna-sql-agent/issues/tool-permission-revoke-all-becomes-allow-all]]
