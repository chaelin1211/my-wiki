---
type: session-log
project: kacportal
date: 2026-08-12
duration: ""
focus: "언론동향 기사수집 차트 x축 기간순 정렬 수정 + 로컬 실행환경 재구축(저장소 무수정) + 법령검색 ES 점수 이슈 1차 분석"
tools-used: [claude-code, chrome-browser-automation, oracle-jdbc]
outcome: partial
---

# 2026-08-12 — 기사 수집 건수 차트 x축 정렬 수정 · 로컬 실행환경 · 법령검색 점수 분석

## 목표

1. 언론(홍보) 동향 분석 > 기사 수집 건수 차트의 x축이 기간 순서대로 안 나오는 문제를 잡는다.
2. 그 검증을 위해 로컬에서 앱을 띄운다 (저장소는 최대한 건드리지 않고, Antigravity의 Run and Debug로).
3. (후반) `LawSearchController` 검색이 기대대로 랭킹되지 않는 문제를 본다.

## 수행한 작업

1. 차트 데이터 경로 추적: `MediaArticle_SQL.xml`(5개 기간별 쿼리) → `ArticleAnalysisServiceImpl` → `articleAnalysis.jsp` → `dashboard.jsp`의 `mediaUtils.renderBarChart`. SQL은 모두 `ORDER BY` 가 걸려 있고 자바 경로에도 재정렬이 없음을 확인.
2. **1차 진단(오진):** "DevExtreme가 문자열 라벨(`8월`, `Q3`)을 자체 정렬한다"고 판단하고 `argumentAxis.categories`만 고정하는 2줄 수정을 넣음. → 이후 실측으로 **틀린 것으로 확인**(아래 "배운 것").
3. 로컬 실행환경 구축: `pom.xml`의 cargo 설정이 여전히 깨져 있어(`<property name=…>`) `mvn cargo:run` 즉시 실패. 사용자가 "저장소는 건드리지 말라"고 해서 **저장소 밖 러너**(`~/dev/mobigen/kacportal-run/`)로 우회 — 별도 pom + `run.sh`.
4. Antigravity(Run and Debug)에서 한 번에 실행되도록 `.vscode/launch.json` 단독 구성으로 정리. Maven을 classworlds Launcher로 직접 띄우는 java launch 구성이라 **tasks.json 없이 실행+디버그가 동시에** 된다. `.gitignore`에 `.vscode/` 추가.
5. 오늘 날짜 기준 데이터가 없어(실데이터는 2025-12-08까지) 화면이 비는 문제 → 개발 Oracle에 테스트 데이터를 넣는 SQL 작성(`~/dev/mobigen/kacportal-run/testdata_media.sql`). 제외키워드 테이블(`A_ANL_F_NEWS_EXCL_KYWD_MNG_INFO`)에 걸리지 않는 키워드만 사용, `RMRK='CLAUDE_TEST'` 마킹으로 정리 가능하게 함. 실행은 사용자가 직접.
6. **재현 실패 → 재조사:** 사용자가 "상용에서는 `8/2~8/8`, `6/28~7/4`, `7/5~7/11` 순서로 나온다(데이터는 8/2 주에만 있음)"고 제보. 실제 `dx.all.js`로 재현 페이지를 만들어 브라우저로 렌더시켜 보니 **입력 순서 그대로 렌더**됨 → 클라이언트 자동정렬 가설 폐기.
7. **최종 수정(방어):** 표시 라벨로는 정렬이 불가능하므로(월간은 `9월…8월`, 주간은 연도 없음), 서버가 이미 갖고 있는 `ChartDataVO.getLabelISO()`(=쿼리의 `YYYY-MM-DD` 원본)를 JSP에서 같이 내려주고, JS에서 그 기준으로 정렬 후 `argumentAxis.categories`로 축을 고정. `labelISO`가 없으면 원본 순서 유지(무해한 폴백).
8. 검증: 상용 관측 순서를 그대로 입력 → 기간순으로 렌더되는 것을 브라우저로 확인. `${item.labelISO}` EL 프로퍼티 존재를 `java.beans.Introspector`로 확인. 5개 기간 타입(해 넘김 케이스 포함) 정렬 결과를 노드로 전수 확인.
9. `dev` 브랜치에 JSP 2개만 커밋 (`47af1dea2`).
10. 법령검색 이슈로 전환 — `LawSearchServiceImpl.parseSearchCondition()`의 `multi_match`에 옵션이 하나도 없는 것을 확인. ES 직접 조회는 정책상 막혀 1차 분석까지만.

## 핵심 결정

- **결정 1:** 근본 원인(상용에서 왜 그 순서로 오는지) 규명 전에 **화면단 방어 수정**을 먼저 넣는다.
  → 사용자 판단("그냥 웹에서 정렬 넣자 일단"). 서버가 어떤 순서로 주든 화면은 항상 기간순이 되므로 회귀 위험이 낮다고 보고 진행.
- **결정 2:** 정렬 기준은 표시 라벨이 아니라 `labelISO`.
  → 표시 라벨 기준 정렬은 **월간·분기가 해를 넘길 때 오히려 더 틀린다**(`1월`/`Q1`이 맨 앞으로 튐). ISO(`2025-09-01`)면 문자열 비교만으로 기간순이 보장됨.
- **결정 3:** 로컬 실행 설정은 저장소 밖(`~/dev/mobigen/kacportal-run/`)에 두고, 저장소에는 `.vscode/`(gitignore) + JSP 수정만 남긴다.
  → [[../issues/local-tomcat-cargo-run-setup-broken|기존 이슈]]에서 정리한 pom 문법 오류를 이번에도 커밋하지 않기로 한 사용자 방침과 일치.

## 배운 것

- **DevExtreme dxChart는 이산축(문자열 인자) 데이터를 자체 정렬하지 않는다.** 데이터 순서를 그대로 렌더한다. `dataPrepareSettings: {sortingMethod: true}` 라는 기본값이 `dx.all.js` 안에 있어 "정렬한다"고 오해하기 쉬운데, 실제 렌더 결과는 입력 순서였다. 추측 대신 실제 라이브러리로 렌더해 보는 것이 유일하게 신뢰할 만한 확인 방법이었다.
- 표시용 라벨과 정렬용 키는 분리해야 한다. `M/d~M/d`, `N월`, `QN` 처럼 **연도가 소거된 라벨은 정렬 키로 쓸 수 없다.**
- cargo embedded tomcat에서 `<context>ROOT</context>`는 표준 Tomcat 관례와 달리 **컨텍스트 경로가 `/ROOT`가 된다.** 루트 배포는 `<context>/</context>`.
- cargo가 배포하는 exploded 디렉토리(`target/sht_webapp`)를 docBase로 직접 물기 때문에, **JSP는 재기동 없이 즉시 반영**된다(Jasper `development=true` 기본값). 단 `src/main/webapp` 수정은 반영되지 않으므로 `mvn -o war:exploded`(약 4.7초) 또는 rsync로 동기화가 필요하다.
- **`target/classes`에 IDE(JDT)가 컴파일한 깨진 클래스가 섞일 수 있다.** 오늘 `ActiveProfileLogger`가 `Unresolved compilation problems: The import org.apache.log4j cannot be resolved`를 던지며 Spring 컨텍스트 기동이 통째로 실패했다. `war:exploded`가 그걸 배포본에 덮어써서 발생. `mvn compile`로 다시 컴파일하면 해결.
- 백그라운드로 띄운 Maven/Tomcat JVM은 셸을 죽여도 **살아남아 포트를 계속 점유**한다. 전부 404가 나면 좀비 프로세스를 의심할 것(`pkill -f classworlds.launcher.Launcher`).

## 문제 & 해결

- **문제:** 기사 수집 건수 차트 x축이 기간 순서로 표시되지 않음 (상용).
- **원인:** **미확인.** 클라이언트 렌더링과 자바 경로는 배제됐고, 남은 것은 서버(Tibero)에서 오는 결과 순서.
- **해결:** 화면단에서 `labelISO` 기준 정렬 + `categories` 고정으로 방어 (`47af1dea2`).
  → 이슈: [[../issues/media-chart-x-axis-order|기사 수집 건수 차트 x축 기간순 정렬 오류]]

- **문제:** `mvn cargo:run` 이 여전히 즉시 실패 (2026-07-15 세션과 동일한 pom 문법 오류).
- **원인/해결:** [[../issues/local-tomcat-cargo-run-setup-broken]] 참고. 이번에는 pom을 고치지 않고 **저장소 밖 러너 pom**으로 우회.

- **문제(진행 중):** 법령 검색에서 `재난 방지법` 검색 시, 두 단어가 모두 든 짧은 문서가 상위에 오지 않음.
- **1차 분석:** `LawSearchServiceImpl.parseSearchCondition()`의 `multi_match`가 옵션 없이 기본값으로 실행됨
  → `operator: OR` + `minimum_should_match` 없음(두 단어 다 든 문서를 우대하는 장치가 전무),
  `type: best_fields` + `tie_breaker: 0`(여러 필드 중 최고 점수 한 개만 사용 → 제목/본문에 단어가 나뉘어 걸리면 조합이 점수에 반영되지 않고, BM25 길이 정규화 비교 기준도 필드마다 달라짐).
  정렬은 문제 없음 — 기본 `orderType=ACCURACY`이고 `LawSearchType.orderFieldByType`에 ACCURACY 항목이 없어 `sortOptions=null` → `_score` 정렬.
- **미해결:** 인덱스 매핑/분석기 확인 필요(`방지법`의 nori 분해 여부, 제목 필드 norms). 개발 ES(`192.168.105.14:12511`) 조회가 정책상 차단되어 중단.

## 다음 할 일

- [ ] 상용에서 `window.weeklyChartData.map(d => d.label)` 확인 → 서버가 준 순서가 실제로 뒤섞였는지 확정 (차트 근본 원인 규명)
- [ ] 위가 뒤섞였다면 Tibero에서 `selectWeeklyStats` 원문 실행해 반환 순서 확인
- [ ] `MediaArticle_SQL.xml`의 주 시작 계산 `MOD(TO_CHAR(날짜,'D') - 1, 7)` — `'D'`는 NLS_TERRITORY 의존이라 상용(Tibero) 세션 설정에 따라 **주 경계가 하루 밀릴 수 있음**. 별개 버그로 확인 필요
- [ ] 법령검색: ES 매핑 확인 후 `multi_match` 옵션 수정안 확정 (`cross_fields`+`and` vs `minimum_should_match`, 제목 `match_phrase` 가산점)
- [ ] 개발 DB 테스트 데이터 정리 — `DELETE FROM IDP_ANL.A_ANL_F_NEWS_EXTR_KYWD_INFO WHERE RMRK='CLAUDE_TEST'`
- [ ] `.claude/settings.json`(bgIsolation 옵트아웃) 정리 여부 결정

## 효과적이었던 프롬프트

```
아니 잘 나오는데 왜 상용에선 그렇게 나와
```

→ 내 오진(“DevExtreme가 정렬한다”)을 붙잡고 계속 파고들던 흐름을, 실측 결과와 상용 관측이 어긋난다는 사실로 되돌린 지점. 이후 "상용에서는 8/2~8/8, 6/28~7/4, 7/5~7/11 순서"라는 **구체적 관측값**을 준 것이 결정적이었다. 증상을 추상적으로("뒤죽박죽") 말할 때보다 실제 순서를 그대로 붙여줬을 때 가설이 즉시 좁혀졌다.
