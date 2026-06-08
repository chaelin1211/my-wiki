---
type: pattern
tags: [dark-mode, css, tailwind, oklch, ux]
created: 2026-06-02
project-origin: dna-sql-agent-web
---

# 다크모드 명도 계층 패턴

## 문제

다크모드에서 hover 배경이 오히려 더 어두워지는 현상.
`hover:bg-muted`를 쓰는데 muted가 카드 배경보다 명도가 낮으면 역방향 표시됨.

## 패턴

다크모드 배경 토큰의 **명도(L) 순서**를 반드시 오름차순으로 유지한다.

```
background < card < muted < accent
```

OKLCH 예시:
```css
--background: oklch(0.24 ...);   /* 페이지 베이스 */
--card:       oklch(0.27 ...);   /* 카드 / 목록 */
--muted:      oklch(0.40 ...);   /* hover / 비활성 */
--accent:     oklch(0.58 ...);   /* 강조 hover */
```

## 주의

- `--muted`를 hover 배경으로 쓰는 경우, 반드시 실제 배경(`--card` 또는 `--background`) 명도보다 높아야 함
- `space-y-*` 대신 `flex flex-col gap-*` 사용 권장 (Tailwind v4에서 `space-y` 마진 방식이 일부 컴포넌트와 충돌)
- outer div가 클릭 처리 + inner Button 패턴: inner Button에 `pointer-events-none` 추가해 이중 hover 방지

## 관련

- [[decisions/012-color-system-neutral-gray-orange]]
