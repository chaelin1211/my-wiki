---
type: decision-record
project: dna-sql-agent-web
date: 2026-05-20
status: accepted
superseded-by: ""
tags: [toast, ux, ui]
---

# ADR-002: Toast 피드백 JSX 아이콘 패턴 채택

## 맥락

Toast를 `toast({ title: '...' })` 단순 문자열로 호출하면 아이콘이 없어 성공/오류 구분이 직관적이지 않음. 프로젝트 내 파일마다 호출 방식이 달랐고, 어드민 쪽은 영문, 사용자 쪽은 한국어로 섞여 있었음.

## 선택지

### 옵션 A: 단순 title/description 문자열 유지
- **장점:** 코드 간결
- **단점:** 아이콘 없어 성공/오류 시각적 구분 약함

### 옵션 B: JSX description에 아이콘 포함
- **장점:** 아이콘으로 즉각적 피드백 타입 인지, 일관된 디자인
- **단점:** 코드 약간 길어짐

## 결정

**옵션 B — JSX 아이콘 패턴을 표준으로 채택한다.**

- 성공: `CheckCircle2` (green, `text-green-500`) + 제목 span
- 오류: `AlertTriangle` (red, `currentColor` 상속) + 제목 span + 설명 span

## 근거

사용자가 텍스트를 읽기 전 아이콘 색상만으로 결과를 인지할 수 있어 UX가 향상됨. shadcn `description` prop이 `React.ReactNode`를 허용하므로 추가 라이브러리 없이 구현 가능.

## 결과

- `components/mypage/account-password-form.tsx`: CheckCircle2 패턴 적용
- `components/conversation-list.tsx`: AlertTriangle 패턴 2곳 적용
- `docs/ui-components-design.md`: 패턴 문서화
- `docs/toast-preview.html`: 시각적 미리보기 제공
- 어드민 쪽 toast는 추후 한국어 + JSX 패턴으로 마이그레이션 예정

## 참고 자료

- [[docs/ui-components-design.md]]
- [[docs/toast-preview.html]]
