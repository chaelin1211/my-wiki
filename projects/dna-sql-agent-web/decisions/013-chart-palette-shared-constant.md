---
type: decision-record
project: dna-sql-agent-web
date: 2026-06-08
status: accepted
superseded-by: ""
tags: [chart, color, echarts, plotly, devextreme]
---

# ADR-013: 차트 공통 컬러 팔렛트를 정적 상수 파일로 관리

## 맥락

ECharts, Plotly, DevExtreme 세 차트 엔진을 사용 중이며, 각 엔진에서 컬러 팔렛트를 별도로 하드코딩하고 있었다. 디자인 컬러를 변경할 때 세 곳을 모두 수정해야 하는 문제가 있었다.

## 선택지

### 옵션 A: 정적 상수 파일 (`lib/chart-palette.ts`)
- **장점:** 단순, 변경 시 한 곳만 수정, 런타임 비용 없음
- **단점:** 차트 컴포넌트들이 직접 import해야 함
- **비용/노력:** 매우 낮음

### 옵션 B: React Context
- **장점:** 런타임에 동적으로 팔렛트 교체 가능
- **단점:** 팔렛트가 정적이라 오버엔지니어링, Provider 추가 필요
- **비용/노력:** 중간

### 옵션 C: 엔진별 컴포넌트에 각각 하드코딩 유지
- **장점:** 없음
- **단점:** 변경 시 세 곳 수정, 동기화 오류 위험
- **비용/노력:** 낮지만 유지보수 비용 높음

## 결정

**옵션 A를 선택한다.** `lib/chart-palette.ts`에 `CHART_COLORS` 배열을 export하고, 세 컴포넌트에서 import해서 사용한다.

## 근거

차트 팔렛트는 런타임에 바뀌지 않는 정적 설정이다. React Context는 동적 상태를 위한 도구이므로 여기에는 맞지 않는다. 정적 상수로 충분히 단일 출처를 확보할 수 있다.

## 결과

- `lib/chart-palette.ts`: `CHART_COLORS = ['#15a8a8', '#fe5d26', '#bf1363', '#023d60', '#0d6b6b', '#ffa07a', '#7b0d42', '#1a7fb5']`
- `echarts-chart-block.tsx`: `color: CHART_COLORS`
- `chart-block.tsx` (Plotly): `colorway: CHART_COLORS`
- `devextreme-chart-block.tsx`: `palette={CHART_COLORS}`
- 팔렛트 변경 시 `lib/chart-palette.ts` 한 파일만 수정하면 됨

## 참고 자료

- PR #37
