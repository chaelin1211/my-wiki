---
type: troubleshooting
project: kacportal
date: 2026-08-12
resolved: false
root-cause: "미확인 — 상용(Tibero)에서 반환되는 결과 순서로 좁혀졌으나 확정 못함. 화면단 방어만 적용."
related: [local-tomcat-cargo-run-setup-broken]
tags: [devextreme, dxchart, tibero, sorting, media-analysis, misdiagnosis]
confidence: medium
---

# 기사 수집 건수 차트 x축이 기간 순서로 표시되지 않음

## 증상

언론(홍보) 동향 분석 > 기사 수집 건수 탭의 막대차트 x축이 기간 순서가 아니라 뒤섞여 표시됨.

상용 관측(주간 탭, 데이터는 `8/2~8/8` 한 주에만 있는 상태):

```
8/2~8/8 | 6/28~7/4 | 7/5~7/11 | ...
```

즉 **값이 있는 주가 맨 앞**, 나머지는 시간순. 단순 문자열 정렬로는 나올 수 없는 패턴이다.

## 환경

- **화면:** `/frn/media/analysis.do` (`dashboard.jsp` + `sections/articleAnalysis.jsp`)
- **차트:** DevExtreme dxChart 24.1.3 (`js/lib/dx.all.js`), 이산(discrete) 인자축
- **데이터:** `MediaArticle_SQL.xml` — `selectDaily/Weekly/Monthly/Quarterly/YearlyStats`
- **DB:** 개발 Oracle(재현 안 됨) / **상용 Tibero(재현됨)**

## 배제된 것 (실측 기준)

1. **클라이언트 렌더링 — 배제.** 같은 `dx.all.js`에 서버 순서대로 6주 데이터를 넣어 실제로 렌더시킨 결과, **입력 순서 그대로** 표시됐다.
   > [!warning] 초기 오진
   > 처음에는 "DevExtreme가 문자열 카테고리(`8월`, `Q3`)를 알파벳순으로 자체 정렬한다"고 진단했다. `dx.all.js` 안에 `dataPrepareSettings: {sortingMethod: true}` 기본값이 있어 그럴듯했지만, **실제 렌더 결과는 입력 순서였다.** 라이브러리 소스 grep만으로 결론 내린 것이 오류였다.
2. **서버 자바 경로 — 배제.** DAO 결과 리스트가 JSP까지 그대로 전달된다. 재정렬·Map 재구성 없음(`ArticleAnalysisAssembler`의 `HashMap`은 요약 증감률 계산 전용, YEARLY 축약만 별도 처리).
3. **매퍼 분기 — 배제.** DbType별 SQL 파일 분기 없음. `mapper/kac/**/*.xml` 한 벌만 로드된다(`context-mapper.xml`).
4. **정렬 옵션 — 배제.** 기본 `orderType=ACCURACY`이며 정렬 필드가 매핑되지 않아 `sortOptions=null`.

## 남은 가설

SQL 결과 순서. 5개 쿼리 모두 `ORDER BY` 가 있는데도 상용에서 그 순서로 온다면 Tibero 쪽 동작을 봐야 한다. 확인 방법:

1. 상용 브라우저 콘솔에서 `window.weeklyChartData.map(d => d.label)`
   - 뒤섞여 있으면 → 서버/쿼리 문제 확정
   - 정상이면 → 렌더 단계 재조사
2. Tibero에서 `selectWeeklyStats` 원문을 상용 기준일로 직접 실행해 반환 행 순서 확인

## 적용한 조치 (방어)

근본 원인 규명 전에 화면단에서 순서를 고정했다. 커밋 `47af1dea2` (`dev`), JSP 2개:

**`sections/articleAnalysis.jsp`** — 정렬 키를 함께 내려보냄

```jsp
{ label: '${item.label}', labelISO: '${item.labelISO}', value: ${item.value} }
```

**`dashboard.jsp` (`mediaUtils.renderBarChart`)** — 정렬 후 축 고정

```js
const hasISO = Array.isArray(data) && data.every(d => d && d.labelISO);
const chartData = hasISO
    ? [...data].sort((a, b) => String(a.labelISO).localeCompare(String(b.labelISO)))
    : data;
const categories = [...new Set(chartData.map(d => d[argumentField]))];
// dataSource: chartData, argumentAxis: { categories, ... }
```

### 왜 `labelISO` 여야 하는가

표시 라벨은 정렬 키로 쓸 수 없다. `ChartDataVO.getLabel()`이 기간 타입별로 가공하면서 **연도를 지우기 때문**이다.

| 탭 | 표시 라벨 | 라벨 기준 정렬 시 |
|---|---|---|
| 월간 | `9월 … 8월` | `1월`이 맨 앞으로 → **더 틀림** |
| 분기 | `Q3, Q4, Q1, Q2` | `Q1`이 맨 앞으로 → **더 틀림** |
| 주간 | `12/28~1/3` | 연말·연초 뒤집힘 |

`getLabelISO()`는 쿼리의 `TO_CHAR(..., 'YYYY-MM-DD')` 원본을 그대로 돌려주므로(5개 쿼리 전부 동일 형식) 문자열 비교만으로 기간순이 보장된다. YEARLY는 `ArticleAnalysisAssembler.shrinkToCurrentYearOnly()`가 `YYYY-01-01`로 표준화하므로 역시 안전(어차피 1건).

`labelISO`가 없으면 정렬하지 않고 원본 순서를 쓰므로 기존 동작보다 나빠지지 않는다.

## 검증

- 상용 관측 순서를 그대로 입력 → 기간순 렌더 확인(브라우저 실측, 값 매칭도 정상)
- `${item.labelISO}` EL 프로퍼티 존재 확인 (`java.beans.Introspector`)
- 5개 기간 타입 전수 확인 — 특히 해 넘김 케이스(월간 `9월→…→1월→8월`, 분기 `Q3→Q4→Q1→Q2`)
- `renderBarChart` 호출부가 한 곳(`media.article.renderChart`)뿐이라 다른 차트 영향 없음

## 곁가지 발견

`MediaArticle_SQL.xml`의 주 시작 계산이 `MOD(TO_CHAR(날짜,'D') - 1, 7)` 인데, `'D'`는 **NLS_TERRITORY 의존**이다. 상용 세션 설정에 따라 1=일요일/1=월요일이 갈려 **주 경계가 하루 밀릴 수 있다.** 순서 문제와는 별개이며 미확인.
