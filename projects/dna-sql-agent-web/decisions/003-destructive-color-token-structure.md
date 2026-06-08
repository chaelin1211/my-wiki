---
type: decision-record
project: dna-sql-agent-web
date: 2026-05-21
status: accepted
superseded-by: ""
tags: [css, design-system, tailwind, shadcn]
---

# ADR-003: destructive 색상 토큰 구조 정의

## 맥락

shadcn/ui 기본 설치 시 `--destructive` CSS 변수가 빨간색이 아닌 보라/회색 계열로 잘못 정의되어 있었다 (`oklch(0.94 0.02 280)`). 이 상태에서 `bg-destructive`를 써도 빨간 배경이 나오지 않아 삭제 확인 팝업 버튼에 `bg-red-600` 하드코딩이 생겼고, 토스트·드롭다운 삭제 항목의 색도 의도와 다르게 표시되었다.

위험 동작(삭제, 오류)을 나타내는 UI 요소가 세 종류의 다른 패턴으로 구현되어 있었다:

| 요소 | 원하는 모양 |
|------|------------|
| 토스트 (오류/경고) | 배경 유지, **글자만 빨간색** |
| 드롭다운 삭제 항목 | 배경 없음, **글자/아이콘만 빨간색** |
| 확인 팝업 삭제 버튼 | **빨간 배경**, 흰 글자 |

## 선택지

### 옵션 A: 컨텍스트마다 하드코딩
- **장점:** 즉시 적용 가능
- **단점:** `bg-red-600`, `text-red-600` 등이 코드베이스에 산재. 다크 모드 대응 불가, 브랜드 색상 변경 시 전수 수정 필요
- **비용/노력:** 낮음 (지금 당장은)

### 옵션 B: CSS 변수 구조를 의미론적으로 재정의
- **장점:** 시멘틱 클래스(`bg-destructive`, `text-destructive`)만으로 세 케이스 모두 커버. 다크 모드 자동 대응. 변경 시 토큰 2개만 수정
- **단점:** 기존 shadcn 기본값과 다르므로 업그레이드 시 주의 필요
- **비용/노력:** 낮음 (변수 2개 수정 + 사용처 class명 통일)

## 결정

**옵션 B: CSS 변수를 의미론적으로 재정의한다.**

```css
/* 라이트 모드 */
--destructive: oklch(0.577 0.245 27.325);   /* 빨간색 — 버튼 배경 / 텍스트 기준색 */
--destructive-foreground: oklch(1 0 0);      /* 흰색  — 빨간 배경 위의 글자 */

/* 다크 모드 */
--destructive: oklch(0.637 0.237 25.331);
--destructive-foreground: oklch(1 0 0);
```

## 근거

`--destructive` = "위험 동작의 기준색(빨간)", `--destructive-foreground` = "그 위에 올라가는 글자색(흰)"으로 역할을 명확히 분리하면 모든 사용처를 시멘틱 클래스로 일관되게 표현할 수 있다.

| 요소 | 적용 클래스 |
|------|------------|
| 토스트 글자 | `text-destructive` |
| 드롭다운 삭제 글자/아이콘 | `text-destructive` |
| 확인 팝업 버튼 배경 | `bg-destructive text-destructive-foreground` |

## 결과

- `globals.css`의 `--destructive`, `--destructive-foreground` 값 변경
- `components/ui/toast.tsx`: destructive variant를 `text-destructive-foreground` → `text-destructive`로 수정
- `components/conversation-list.tsx`: 드롭다운 삭제 항목을 `text-destructive`로 통일, 확인 팝업 버튼은 `bg-destructive text-destructive-foreground` 사용
- shadcn/ui 컴포넌트 업데이트 시 `--destructive` 변수 값이 덮어쓰여질 수 있으므로 주의

## 참고 자료

- [shadcn/ui theming 문서](https://ui.shadcn.com/docs/theming)
