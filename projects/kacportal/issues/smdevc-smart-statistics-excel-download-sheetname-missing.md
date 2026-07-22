---
type: troubleshooting
project: kacportal
date: 2026-07-15
resolved: true
root-cause: "xl 객체에 sheetName 속성 누락 → commonLib.makeXl()의 xl.sheetName.toString()에서 TypeError"
related: [local-tomcat-cargo-run-setup-broken]
tags: [javascript, excel, tabulator, exceljs, frontend]
---

# 스마트기기 이용통계 화면 엑셀 다운로드 버튼이 동작하지 않음

## 증상

`smDevcSmartStatistics.jsp` 화면에서 "엑셀 다운로드" 버튼을 클릭해도 아무 파일도 다운로드되지 않고 조용히 실패함(사용자 입장에서는 "그냥 안 됨"으로만 보임). 콘솔에는 다음 에러가 찍힘:

```
TypeError: Cannot read properties of undefined (reading 'toString')
    at Object.makeXl (commonLib.js:1100:43)
```

## 환경

- **OS:** macOS (로컬 dev), 운영은 사내 Tomcat
- **런타임:** Java 8, Spring MVC, Tabulator 6.3.0, ExcelJS
- **관련 패키지:** `report/js/common/commonLib.js`, `report/js/smDevcSmartStatistics.js`
- **재현 조건:** 스마트기기 이용통계 화면 진입 후 엑셀 다운로드 버튼 클릭 시 100% 재현

## 시도한 것들

1. ✅ `smDevcSmartStatistics.jsp` → `.js` → `commonLib.js` 순으로 콜스택 추적, `makeXl()` 1행에서 `xl.sheetName.toString()`이 실패 지점임을 확인
2. ✅ 다른 유사 report 화면들(`smDevcSelfKiosk.js`, `smDevcBioPassenger.js`, `smDevcSmartStatus.js` 등)과 비교, 모두 `xl` 객체에 `sheetName`을 넘기고 있는데 이 화면만 빠져 있는 것을 확인
3. ✅ DB 연결 없이 검증하기 위해 정적 샘플 HTML 페이지(`test-excel-sample.html`)로 실제 `commonLib.makeXl()`을 그대로 호출해 재현 및 수정 확인

## 근본 원인

`smDevcSmartStatistics.js`의 엑셀 다운로드 버튼 클릭 핸들러가 만드는 `xl` 설정 객체에 `sheetName` 프로퍼티가 빠져 있었음. 원래 주석 처리된 예전 코드(`table.download("xlsx", ..., {sheetName:"..."})`)에는 sheetName이 있었는데, `commonLib.makeXl()` 방식으로 리팩터링하면서 옮기지 않고 누락된 것으로 보임.

`commonLib.js`의 `makeXl(xl)` 함수 첫 줄이 `wb.addWorksheet(xl.sheetName.toString()...)`이라, `sheetName`이 `undefined`면 즉시 예외가 나서 워크북 생성 자체가 시작되지 않는다.

## 해결 방법

```js
var xl = {
    titlClss: '스마트기기 이용통계_'+ fn_getTodayTime(),
    titlUse: false,
    sheetName: '공항별 항공사별 스마트기기 이용통계(월별)',  // ← 추가
    srchClss: null,
    ...
};
```

## 예방책

- `commonLib.makeXl()`처럼 여러 화면이 공유하는 헬퍼는, 필수 옵션(`sheetName` 등)이 빠졌을 때 `undefined.toString()`류의 불친절한 예외 대신 명확한 에러 메시지를 던지도록 방어 코드를 넣으면 다음에 같은 실수가 나도 원인 파악이 빨라짐. (이번 세션에서는 반영하지 않음, 다음에 고려)
- 새 report 화면을 만들 때 기존 화면(`smDevcSelfKiosk.js` 등)을 복붙 기준으로 삼고, `xl` 객체 필드를 체크리스트처럼 비교하면 이런 누락을 예방 가능.

## 관련 페이지

- [[projects/kacportal/issues/local-tomcat-cargo-run-setup-broken]]
- [[projects/kacportal/sessions/2026-07-15-excel-download-sheetname-bug-tomcat-debug-setup]]
- [[knowledge/patterns/static-html-harness-bypass-missing-db]]
