---
type: troubleshooting
tags: [css, box-sizing, layout, chart, height]
date: 2026-06-15
---

# 고정 높이 셀 안 차트가 짤림 — border-box 크롬 차감 누락

## 증상

그리드/카드 셀(고정 px 높이) 안에 차트를 명시적 px 높이로 렌더할 때, 차트가 카드 영역을 넘쳐 **하단 여백 없이 짤려** 보인다. (예: 같은 데이터인데 한 화면은 314px, 대시보드는 319px로 5px 더 큼)

## 원인

차트 높이를 `셀높이 − 크롬`으로 계산할 때 크롬 합산에서 빠진 요소가 있으면 차트가 가용 공간보다 커진다. 흔히 누락되는 것:

- **카드 루트 자체의 `border`** — `box-sizing: border-box`에서는 border가 셀 높이 *안쪽*을 차지하므로 상하 1+1=2px이 내부 가용 높이를 줄인다. 헤더/푸터의 border와 별개다.
- 헤더/푸터의 실제 높이(자식 요소·`min-h`·`py`·border 포함)를 상수로 박았는데 실제와 1~2px 어긋남.

## 해결

차트 높이 = `셀높이 − (카드 테두리 + 헤더 + 푸터 + 콘텐츠 패딩)` 으로 **모든 크롬을 빠짐없이** 차감한다. 추정하지 말고 px 단위로 분해해 검증할 것.

```
WIDGET_CHROME = 카드 border(2) + 헤더(37) + 푸터(29) + 차트영역 p-2(16) = 84
chartHeight   = cellHeightPx − WIDGET_CHROME
```

헤더처럼 자식에 따라 높이가 흔들리는 영역은 `min-h` 대신 **고정 높이(`h-[37px]`)로 박는** 편이 계산 정합성에 안정적이다. (shadcn `Button size="icon"`은 베이스가 `size-9`=36px라 헤더를 키울 수 있음 — 주의)

## 참고

- [[projects/dna-sql-agent/sessions/2026-06-15-dashboard-preset-responsive-sizing]]
