---
type: decision-record
project: dna-sql-agent
date: 2026-06-05
status: accepted
superseded-by: ""
tags: [echarts, frontend, architecture]
---

# ADR-007: ECharts 레이아웃 책임을 프론트엔드가 전담

## 맥락

ECharts option 생성 시 백엔드(`chart_generator.py`)와 프론트엔드(`echarts-chart-block.tsx`) 양쪽에서 `color`, `grid`, `tooltip.confine` 등 레이아웃 속성을 설정하고 있어 충돌이 발생했다. 특히 백에서 `grid.top/bottom`을 고정값으로 내려보내면 프론트의 legend/visualMap 유무 기반 동적 계산이 무력화됐다.

## 선택지

### 옵션 A: 백엔드가 완전한 option 생성
- **장점:** 한 곳에서 관리
- **단점:** 컨테이너 크기, 다크모드, legend 유무 등 렌더링 컨텍스트를 백이 알 수 없음

### 옵션 B: 프론트엔드가 레이아웃 전담, 백은 데이터 인코딩만
- **장점:** 렌더링 컨텍스트는 프론트만 알 수 있음. 충돌 없음
- **단점:** 백/프론트 양쪽 코드 이해 필요

### 옵션 C: 하이브리드 — 속성별로 명확히 소유권 정의
- **장점:** 유연성
- **단점:** 소유권 경계가 불명확해지면 다시 충돌

## 결정

**옵션 B를 선택한다.**

## 근거

- `grid.bottom`은 legend/visualMap 유무에 따라 달라짐 → 프론트만 알 수 있음
- 차트 높이는 컨테이너, 북마크 고정 여부, sankey 노드 수 등 렌더링 컨텍스트 의존
- 백엔드는 어떤 환경에서 렌더될지 모름 (채팅뷰 vs 북마크뷰 vs PDF 등)

## 결과

**백엔드 책임 (데이터 종속):**
- `series.type`, `series.data`, `series.stack/smooth/areaStyle`
- `xAxis/yAxis.type`, `xAxis.data`
- `visualMap.min/max/dimension/inRange`
- `legend.data` (그룹명)
- `tooltip.trigger`, `tooltip.formatter`

**프론트엔드 책임 (렌더링 컨텍스트 종속):**
- `color` palette
- `tooltip.confine`
- `grid` (top/bottom/left/right/containLabel)
- 차트 높이 (BASE_HEIGHT, heatmap 행 수, sankey 노드 수 기반)
- `backgroundColor`

**`resolvedOption` 머지 전략:**
```ts
{
  backgroundColor: 'transparent',
  color: COLOR_PALETTE,       // 프론트 기본값
  ...option,                  // 백엔드 (color 덮어쓰기 가능)
  tooltip: { confine: true, ...option.tooltip },
  grid: { top, bottom, containLabel: true, ...option.grid },
}
```

- 알려진 트레이드오프: 백/프론트 양쪽 코드를 함께 봐야 전체 option 파악 가능
- 향후 재검토: 서버사이드 렌더링(차트 이미지 생성) 필요 시 백이 완전한 option을 갖도록 변경 필요

## 참고 자료

- `src/dna/integrations/echarts/chart_generator.py`
- `components/echarts-chart-block.tsx`
- [[sessions/2026-06-05-echarts-scatter-bubble-refactor]]
