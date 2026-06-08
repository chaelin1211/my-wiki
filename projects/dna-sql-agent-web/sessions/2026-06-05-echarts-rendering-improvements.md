---
type: session-log
project: dna-sql-agent-web
date: 2026-06-05
duration: ~3h
focus: "ECharts 렌더링 개선 (Sankey 높이, grid 기본값, 코드 정리) 및 대화 제목 덮어쓰기 버그 분석"
tools-used: [claude-code]
outcome: success
---

# 2026-06-05 — ECharts 렌더링 개선 및 대화 제목 버그 분석

## 목표

- Sankey 차트 높이가 부족해 노드가 잘리는 문제 해결
- Scatter 등 일반 차트 좌하단 여백 문제 개선
- 대화 제목이 사용자 수정 후 다시 다른 값으로 바뀌는 원인 파악
- EChartsBlock 코드 정리

## 수행한 작업

1. **워크트리 정리**
   - 남아있던 `.claude/worktrees/majestic-wobbling-knuth` 제거
   - 앞으로 worktree 미사용 설정 (메모리 기록)

2. **Sankey 높이 동적 계산**
   - 전체 노드 수 → **최대 열 노드 수** 기반으로 변경
   - links에서 source-only / target-only / both 노드 분류 → 가장 조밀한 열 기준
   - 좌우 비대칭 Sankey에서도 적절한 높이 산출
   - 수식: `max(400, maxColumnNodes * 10 + 200)`

3. **북마크에서 Sankey scale-down**
   - `height` prop(고정)이 `naturalHeight`보다 작으면 CSS `transform: scale`로 축소
   - 히트맵이 ECharts 내부에서 자동 압축되는 것과 동일한 효과

4. **grid 기본값 개선**
   - `left: 10, right: 10, containLabel: true` 추가 → 좌하단 여백 및 레이블 클리핑 해결
   - Sankey는 grid 미주입 (ECharts sankey가 grid 무시하면서 여백 발생했던 것 수정)

5. **gridBottom 조건 세분화**
   - 기존: `visualMap || 바닥 legend → 80`
   - 변경: `visualMap → 80`, `바닥 legend만 → 40`, `없음 → 12`
   - visualMap: `show !== false && top === undefined` 조건으로 위치/표시 여부 확인

6. **resolvedOption 구조 개선**
   - `backgroundColor: 'transparent'`를 `...option` 뒤로 이동 → 항상 투명 보장
   - `color: COLOR_PALETTE`는 `...option` 앞 → 백엔드 color 있으면 덮어쓸 수 있음
   - `tooltip: { confine: true }` 기본값 추가 (백엔드에서 이동)

7. **EChartsBlock 코드 정리**
   - `getSankeyMaxColumnNodes()`, `calcNaturalHeight()` 헬퍼 함수 분리
   - `BASE_HEIGHT`, `COLOR_PALETTE` 모듈 상수로 분리
   - `chartContent` 변수 → `renderChart()` 함수로 교체

8. **차트 기본 높이 330 → 400** (ECharts/Plotly/DevExtreme 공통)

9. **대화 제목 덮어쓰기 버그 분석**
   - `loadConversationMessages` (use-conversations.ts:154)에서 `detail.title`로 항상 덮어씀
   - 사용자가 rename 후 대화를 다시 선택하면 서버 title로 덮어씌워짐
   - 서버가 저장은 정상 → 백엔드가 메시지 전송 후 자동으로 title 재생성하는지 확인 필요
   - 프론트 방어 옵션: `c.title || detail.title` (타 기기 rename 반영 안 됨)
   - → 수정 보류, 백엔드 확인 후 결정

10. **브랜치 생성 및 커밋**
    - `feat/echarts-rendering-improvements` 브랜치에 커밋 (a48d79b)
    - docs/echarts-chart-design.md 4.7 섹션 현행화

## 핵심 결정

- **Sankey 높이: 최대 열 노드 수 기준** — 전체 노드가 아닌 가장 조밀한 열 기준이 실제 필요 높이와 일치
  → ADR 별도 없음 (기존 ADR-011에 포함)
- **북마크 Sankey: CSS transform scale** — ECharts는 heatmap처럼 sankey를 자동 압축하지 않아 CSS로 구현
- **containLabel: true** — 축 레이블을 grid 안에 포함, 레이블이 길어도 클리핑 없음

## 배운 것

- ECharts heatmap은 행을 자동 압축(주어진 높이에 맞게 분배)하지만, Sankey는 최소 노드 크기 제약으로 인해 클리핑 발생
- ECharts grid에 `containLabel: true`가 없으면 `left: 10`은 plot 영역 시작점이 되어 긴 레이블이 잘릴 수 있음
- ECharts Sankey option에 `grid`를 포함시키면 좌표계 공간을 예약해 여백이 생김 → Sankey는 grid 제외 필요

## 문제 & 해결

- **문제:** Sankey 북마크 카드에서 노드가 잘려 보임
- **원인:** 북마크 고정 높이(314px)가 naturalSankeyHeight보다 작을 때 ECharts가 클리핑
- **해결:** `sankeyScale = height / naturalHeight`로 CSS scale 적용
  → [[issues/sankey-bookmark-clipping]] (범용 이슈 아님, 기록 생략)

- **문제:** Scatter 차트 좌하단에 불필요한 여백
- **원인:** grid.left 기본값 `10%` + containLabel 미설정 → 축 레이블 공간이 별도로 잡힘
- **해결:** `left: 10, right: 10, containLabel: true`

- **문제:** visualMap이 없거나 위에 있어도 gridBottom 80px 적용됨
- **원인:** `!!option.visualMap` 만 체크, 위치·표시 여부 미확인
- **해결:** `vm.show !== false && vm.top === undefined` 조건 추가

## 다음 할 일

- [ ] `feat/echarts-rendering-improvements` PR 생성 및 머지
- [x] 대화 제목 덮어쓰기 — 수정 완료
- [ ] style/ui-spacing 브랜치 PR 생성 및 머지
