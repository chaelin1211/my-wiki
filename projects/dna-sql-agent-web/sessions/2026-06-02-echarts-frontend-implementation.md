---
type: session-log
project: dna-sql-agent-web
date: 2026-06-02
duration: ~5h
focus: "ECharts 프론트엔드 구현 및 SaveBanner 스크롤 인디케이터"
tools-used: [claude-code]
outcome: success
---

# 2026-06-02 — ECharts 프론트엔드 구현 및 SaveBanner 스크롤 인디케이터

## 목표

- ECharts 차트 엔진 프론트엔드 전 구현 (설계서 기반)
- SaveBanner 버튼 영역 모바일 스크롤 인디케이터 추가

## 수행한 작업

### SaveBanner 스크롤 인디케이터 (feat/save-banner-scroll-indicator)

1. `components/settings/ui/shared.tsx` 수정
   - overflow 감지 시 좌우 그라데이션 + 체브론 버튼 표시
   - 기존 `shrink-0 flex-1` 구조 → `flex-1 min-w-0`로 수정 (overflow 감지 fix)
   - 체브론 버튼을 nav 직접 자식으로 배치 (중첩 flex 제거)
   - 데스크탑 우측 정렬: 첫 버튼에 `ml-auto` (overflow 시 자동으로 0이 되어 스크롤 정상 동작)

### ECharts 프론트엔드 구현 (feat/echarts-chart-engine, PR #33)

2. **패키지 설치**: `echarts@6.1.0`, `echarts-for-react@3.0.6`

3. **타입 추가** (`lib/types.ts`): `EChartConfig`, `chart_ec` MessageStep kind

4. **ChartEngine 확장** (`lib/types/settings.ts`): `'echarts'` union 추가

5. **SSE 분기** (`lib/vanna-api.ts`): `onChartEc` callback + `chart_type === 'echarts'` 분기

6. **Hook/Build 연결**: `use-chat-stream.ts`, `build-steps.ts`에 `onChartEc` handler 등록

7. **`EChartsBlock` 신규 생성** (`components/echarts-chart-block.tsx`)
   - 다크모드: MutationObserver + `theme='dark'` + `backgroundColor: 'transparent'`
   - 높이: `height` prop 명시 시 고정, 미명시 시 동적 계산 (히트맵 `yAxisRows * 30 + 120`)
   - `option.dataSource` 있으면 `DataTable` 렌더링 분기
   - `resolvedOption`: grid top/bottom 기본값 주입 (title/legend/visualMap 감지)
     → ADR: [[decisions/011-echarts-frontend-layout]]

8. **chat-message.tsx**: import + `case 'chart_ec'` + 필터 4곳

9. **chat-header.tsx**: 필터 2곳

10. **bookmark-view.tsx**: import + `payload?.option` 감지 분기, 확장 시 동적 높이

11. **agent-tab.tsx**: ECharts ToggleGroupItem 추가

## 핵심 결정

- **ECharts grid 기본값 프론트 주입**: Plotly `margin` 패턴과 동일하게 프론트에서 grid 기본값 덮어쓰기. `containLabel: true` 대신 title/legend/visualMap 유무 기반 top/bottom 분기
  → ADR: [[decisions/011-echarts-frontend-layout]]

- **height 명시/미명시 분기**: 북마크(고정)와 챗(동적)의 컨텍스트 차이를 prop 유무로 구분. `undefined` = 동적, 숫자 = 고정

- **다크모드 `backgroundColor: 'transparent'`**: ECharts dark 테마 배경색을 투명으로 오버라이드. 카드 `bg-card` 배경이 보이도록

## 문제 & 해결

- **문제:** SaveBanner overflow 감지 안 됨 (그라데이션/화살표 미표시)
- **원인:** 래퍼 div에 `shrink-0`이 있어 flex 컨테이너 너비가 제약되지 않음
- **해결:** nav 직접 자식 구조로 단순화, `flex-1 min-w-0`으로 변경

- **문제:** ECharts 히트맵 하단 여백 / visualMap 겹침
- **원인:** grid.bottom 미설정 시 ECharts 기본값(60)이 legend + visualMap 공간과 중복
- **해결:** visualMap/legend 유무에 따라 grid.bottom 동적 주입

- **문제:** ECharts 다크모드 시 배경 검정
- **원인:** `theme='dark'`가 canvas 배경색을 진한 색으로 설정
- **해결:** `backgroundColor: 'transparent'` 오버라이드

## 다음 할 일

- [ ] PR #33 머지
- [ ] 백엔드 ECharts area/stackedBar/stackedArea/spline 추가 옵션 반영 확인
- [ ] URL 라우팅 전환 (Next.js App Router)
