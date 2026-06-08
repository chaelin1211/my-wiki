---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-05-28
resolved: true
root-cause: "bookmark-view.tsx 헤더에 useIsOfficeAddin() 체크 누락"
related: [decisions/008-app-header-shared-component]
tags: [office-addin, header, ppt]
---

# 북마크 헤더에서 PPT 모드 시 마이페이지 버튼 미숨김

## 증상

PPT(Office Add-in) 환경에서 북마크 뷰 상단 헤더에 마이페이지(Settings) 버튼이 그대로 노출됨.
채팅 헤더에서는 정상적으로 숨겨짐.

## 환경

- **재현 조건:** Office Add-in(PowerPoint) 환경에서 북마크 뷰 진입

## 시도한 것들

1. ✅ `useIsOfficeAddin()` 훅으로 감지 후 `!isOfficeAddin` 조건 추가

## 근본 원인

`chat-header.tsx`에는 `useIsOfficeAddin()` 체크가 있었으나, `bookmark-view.tsx`의 헤더는 독립적으로 구현되어 있어 동일한 조건이 누락됨. 공통 로직이 두 곳에 분산된 구조적 문제.

## 해결 방법

`AppHeader` 공통 컴포넌트로 추출하여 마이페이지 버튼 + Office Add-in 조건을 단일 위치에서 관리.
→ [[decisions/008-app-header-shared-component]]

## 예방책

마이페이지 버튼, 다크모드 토글처럼 전역 조건이 걸리는 공통 UI는 반드시 공통 컴포넌트에서 처리. 뷰별 헤더에 직접 구현하지 않는다.

## 관련 페이지

- [[decisions/008-app-header-shared-component]]
- [[sessions/2026-05-28-responsive-ui-pr-and-app-header]]
