---
type: knowledge
tags: [tailwind, shadcn, css, design-system]
created: 2026-05-21
updated: 2026-05-21
---

# Tailwind CSS v4 + shadcn/ui 테마 구조

## CSS 변수 역할 규칙

shadcn/ui의 색상 토큰은 `--색상` (배경/기준색) + `--색상-foreground` (그 위의 글자색) 쌍으로 구성된다.

| 변수 | 역할 |
|------|------|
| `--destructive` | 위험 동작의 기준색 (빨간) |
| `--destructive-foreground` | 빨간 배경 위의 글자색 (흰) |

## destructive 패턴 사용 기준

| 상황 | 클래스 |
|------|--------|
| 빨간 배경 버튼 (확인 팝업 삭제 등) | `bg-destructive text-destructive-foreground` |
| 빨간 글자/아이콘 (드롭다운 항목, 토스트) | `text-destructive` |

## 주의사항

- shadcn/ui 기본 설치 시 `--destructive`가 빨간색이 아닌 보라/회색으로 정의될 수 있음 → 반드시 확인 후 수정
- shadcn 컴포넌트 업데이트 시 `globals.css` 변수가 덮어쓰여질 수 있으므로 주의
- `text-red-600` 같은 하드코딩 대신 시멘틱 토큰 사용 권장

## 관련 ADR

- [[projects/dna-sql-agent-web/decisions/003-destructive-color-token-structure|ADR-003]] — dna-sql-agent-web destructive 토큰 정의 사례
