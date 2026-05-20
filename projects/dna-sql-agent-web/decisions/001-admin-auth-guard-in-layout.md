---
type: decision-record
project: dna-sql-agent-web
date: 2026-05-19
status: accepted
superseded-by: ""
tags: [auth, admin, nextjs]
---

# ADR-001: 어드민 인증 가드를 layout.tsx에서 일괄 처리

## 맥락

`/admin/*` 경로에 비어드민 유저가 URL 직접 입력으로 접근 가능한 문제 발견. 기존에는 각 페이지(`database/page.tsx` 등)에서 개별적으로 `isAdmin` 체크를 하고 있었음.

## 선택지

### 옵션 A: 레이아웃에서 일괄 처리
- **장점:** 한 곳에서 관리, 새 페이지 추가 시 자동 적용
- **단점:** 없음
- **비용/노력:** 낮음

### 옵션 B: 각 페이지에서 개별 처리 (기존 방식 유지)
- **장점:** 페이지별 세밀한 제어 가능
- **단점:** 새 페이지 추가 시 누락 가능, 중복 코드
- **비용/노력:** 낮음

## 결정

**옵션 A를 선택한다.**

## 근거

`/mypage/layout.tsx`와 동일한 패턴. 레이아웃에서 한 번에 처리하면 새 어드민 페이지가 추가될 때 인증 가드 누락 위험이 없다.

## 결과

- `app/admin/layout.tsx`에 `useAuth().isAdmin` 체크 + 미인증 시 `/` 리다이렉트 추가
- 각 페이지의 개별 `isAdmin` 체크는 중복이지만 제거하지 않음 (향후 정리 가능)
- 클라이언트 사이드 가드이므로 백엔드 API 권한 체크도 별도 확인 필요

## 참고 자료

- `app/mypage/layout.tsx` (동일 패턴)
