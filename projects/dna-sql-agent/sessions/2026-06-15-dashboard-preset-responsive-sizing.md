---
type: session-log
project: dna-sql-agent
date: 2026-06-15
duration: ~4h
focus: "대시보드 위젯 크기 모델 — 프리셋·반응형 컬럼·비례 높이·푸터 대화 링크"
tools-used: [claude-code]
outcome: success
---

# 2026-06-15 — 대시보드 위젯 크기/반응형/비례 높이 정리

> [[sessions/2026-06-15-bookmark-dashboard-feature]] 후속 세션. 대시보드 초기 구현 위에 크기·레이아웃 정책을 다듬음.

## 목표

1. 위젯 크기를 자유 리사이즈 대신 고정 프리셋으로 단순화
2. 화면 폭에 따른 반응형 컬럼 + 자연스러운 높이 비율
3. 위젯 푸터에 출처 대화 링크(북마크 카드와 동일 UX)

## 수행한 작업

### 크기 모델 (`lib/chart-height.ts` 신규 모듈)

1. **프리셋 2종 확정** — `최소`(1칸×4행), `최대`(2칸×auto). 자유 리사이즈 폐기(`resizeConfig.enabled=false`).
   - `최대` 높이는 `chartContentHeight`(heatmap y축 행수·sankey 계층 노드수, 그 외 `CHART_BASE_HEIGHT=330`)를 행수로 환산 후 `H_UNIT`(4행) 배수로 올림 스냅.
2. **콘텐츠 높이 로직 추출** — `echarts-chart-block.tsx`의 인라인 heatmap/sankey 높이 계산을 `chartContentHeight()`로 이동(동작 동일).
3. **차트 높이 계산 일원화** — `WIDGET_CHROME`(카드 테두리2 + 헤더37 + 푸터29 + p-2 16 = **84**), `cellChartHeight(rows, rowHeight)`.

### 반응형 + 비례 (`dashboard-detail.tsx`)

4. **너비 단위 1칸** → 그리드 컬럼 수 = 한 줄 위젯 수. `colsForWidth`: ≥1200→4 / ≥700→2 / else 1열.
5. **편집 모드 4열 고정** — 좁은 폭에서 편집·저장 시 narrow 좌표가 저장돼 확장해도 복원 안 되던 문제 해결. 최소 폭 확보 + 가로 스크롤.
6. **비례 높이** — `rowHeightForColWidth = clamp(colWidth × 0.18, 40, 130)`. 폭 따라 위젯이 같이 커짐.
7. **캐노니컬/표시 레이아웃 분리** — `fitToCols`로 좁은 폭 reflow, `onLayoutChange`는 x/y만 반영(w/h 프리셋 유지), `normalizeWidth`로 레거시(16칸) 너비 환산.
8. **드래그 격자 스냅** — react-grid-layout v2 `constraints={[snapToGrid(W_UNIT,H_UNIT), gridBounds]}` (헬퍼는 `react-grid-layout/core` 서브패스).

### 푸터 대화 링크

9. 백엔드: `WidgetResponse`에 `conversation_id`/`conversation_title` 추가, 위젯 조회 쿼리 3곳에 `conversations` 조인.
10. 프론트: 타입·API 매핑·`onNavigateToConversation` 배선(layout→view→detail→widget), 푸터 좌측에 출처 대화 링크(우측 비움).

### 헤더/여백 정리

11. 위젯 헤더 **고정 37px**(`h-[37px]`, 편집/조회 동일) — shadcn Button `size-9` 등으로 높이가 들쭉날쭉하던 문제 차단.
12. 차트 하단 여백 짤림 수정 — 카드 자체 border 2px 누락분을 `WIDGET_CHROME`에 반영.

### 문서/커밋

13. 웹 `docs/dashboard-design.md` 8장을 v2 API + 크기 모델로 전면 갱신, 백엔드 `WidgetResponse` 대화 필드 반영.
14. 커밋(브랜치 `feat/dashboard`, 미푸시): 웹 `196a387`/`26a50a5`/`05612f8`/`86c7eaf`, 백엔드 `3512d2b`/`b535407`/`47f3535`/`4166e20`.

## 핵심 결정

- **결정 1:** 위젯 크기 = 고정 프리셋 2종 + 반응형 컬럼 + 비례 높이 + 캐노니컬/표시 분리 (자유 리사이즈 폐기)
  → ADR: [[decisions/016-dashboard-widget-sizing-model]]
- **결정 2:** 편집 모드는 항상 4열 고정 — 반응형 저장 시 배치 손실 방지 (ADR-016에 포함)

## 배운 것

- react-grid-layout **v2**는 `gridConfig`/`dragConfig`/`resizeConfig` props 구조이고, 위치 스냅 제약(`snapToGrid`/`gridBounds`)은 루트가 아닌 `react-grid-layout/core` 서브패스에서만 export된다.
- shadcn `Button size="icon"`은 베이스가 `size-9`(36px) — 헤더 높이 계산이 흔들림. **헤더를 고정 px로 박는 게 안정적**.
- `box-sizing: border-box`에서 카드 자체 `border`(상하 2px)가 셀 내부 가용 높이를 줄인다 → 차트 높이 계산에 반드시 포함해야 짤림이 없다.

## 문제 & 해결

- **문제:** 좁은 폭에서 편집·저장 후 화면을 넓혀도 위젯이 두 줄로 남음
- **원인:** 편집도 반응형이라 narrow(2열) 좌표가 캐노니컬로 저장됨
- **해결:** 편집 모드를 항상 4열(MAX_COLS)로 고정해 저장 좌표를 캐노니컬로 유지

- **문제:** 위젯 차트가 하단 여백 없이 짤려 보임 (북마크 314 vs 위젯 319)
- **원인:** `WIDGET_CHROME`에 카드 자체 테두리 2px 누락
- **해결:** `WIDGET_CHROME = 84`로 보정 → 차트가 셀 내부에 정확히 맞고 p-2(8px) 하단 여백 유지

## 다음 할 일

- [ ] 대시보드 `feat/dashboard` 브랜치(백+프론트) push 및 PR 생성/머지
- [ ] `최대` 프리셋: 비례 rowHeight가 큰 상태(2열)에서 적용 시 빈 공간 다듬기 검토
- [ ] 기존 위젯 레거시 너비 정규화 후 일괄 보정(저장) 안내

## 효과적이었던 프롬프트

```
실제 렌더 높이를 추정하지 말고 직접 측정해서 원인을 찾아라
(헤더/푸터/카드 border를 px 단위로 분해 → WIDGET_CHROME 정합성 확보)
```
