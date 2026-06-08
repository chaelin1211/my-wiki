---
type: decision-record
project: dna-sql-agent-web
date: 2026-06-02
status: accepted
tags: [echarts, frontend, layout]
---

# ADR-011: ECharts 프론트엔드 레이아웃 전략

## 맥락

ECharts는 백엔드가 완성된 `option` 객체를 내려주는 구조이지만, `grid` 설정 없이 내려올 경우 ECharts 기본값(top/bottom 각 60px)이 적용되어 legend, visualMap, title 유무와 무관하게 과도한 여백이 생긴다.

Plotly는 프론트에서 `margin: { t, r, b, l }`을 항상 덮어쓰고, DevExtreme은 JSX prop 기반으로 자동 처리한다.

## 선택지

### 옵션 A: 백엔드에서 grid 포함
- **장점:** 프론트 로직 없음, option 자체 완결
- **단점:** 백엔드가 legend/visualMap 위치를 계산해야 함. 공수 증가.

### 옵션 B: 프론트에서 grid 기본값 주입 (Plotly 패턴)
- **장점:** 프론트에서 일관된 레이아웃 보장. 백엔드 부담 없음.
- **단점:** 백엔드 option의 grid 설정과 충돌 가능 (spread로 백엔드 우선 처리)

### 옵션 C: containLabel: true 단독 사용
- **장점:** ECharts 자동 계산
- **단점:** left 오프셋 증가로 차트가 우측으로 치우치는 문제 발생

## 결정

**옵션 B를 선택한다.**

```js
const resolvedOption = {
  backgroundColor: 'transparent',
  ...option,
  grid: {
    top: option.title?.text ? 40 : 10,
    bottom: (hasVisualMap || legendAtBottom) ? 80 : 12,
    ...(option.grid ?? {}),  // 백엔드 grid가 있으면 덮어씀
  },
}
```

## 근거

- Plotly와 동일한 패턴으로 일관성 유지
- 백엔드 `option.grid`가 있으면 spread로 덮어써서 충돌 방지
- `containLabel: true`는 left 오프셋 문제로 배제

## 결과

- title 없을 때 `grid.top: 10` → 상단 여백 최소화
- legend bottom 또는 visualMap 있을 때 `grid.bottom: 80` → 겹침 방지
- `backgroundColor: 'transparent'` → 다크모드 카드 배경 유지
- 향후 백엔드가 grid를 포함하면 자동으로 백엔드 값 우선 적용됨
