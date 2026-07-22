---
type: session-log
project: kacportal
date: 2026-07-15
duration: ""
focus: "스마트기기 이용통계 엑셀 다운로드 오류 수정 + 로컬 Tomcat(cargo) 디버그 환경 구축"
tools-used: [claude-code, chrome-browser-automation]
outcome: success
---

# 2026-07-15 — 엑셀 다운로드 버그 수정 + 로컬 Tomcat 디버그 환경 구축

## 목표

`smDevcSmartStatistics.jsp`(스마트기기 이용통계) 화면에서 엑셀 다운로드 버튼이 동작하지 않는 원인을 찾아 수정한다. 겸사겸사 로컬에서 VS Code로 Tomcat을 띄우고 디버깅할 수 있는 환경을 구축한다.

## 수행한 작업

1. `smDevcSmartStatistics.jsp` → `smDevcSmartStatistics.js` → `commonLib.js`의 `makeXl()` 순으로 추적, `xl.sheetName.toString()`에서 `sheetName` 속성 누락으로 즉시 TypeError가 나는 것을 발견 (다른 유사 화면들은 모두 `sheetName`을 넘기고 있었음).
2. `sheetName: '공항별 항공사별 스마트기기 이용통계(월별)'` 추가로 수정.
3. 사용자가 로컬 Tomcat 디버깅 설정을 요청 → `.vscode/launch.json`/`tasks.json`은 이미 있었지만 참조하는 `run-tomcat.sh`/`run-tomcat-debug.sh`가 실제로 없어서 동작하지 않는 상태였음. 스크립트를 새로 작성.
4. 실행해보니 `pom.xml`의 `cargo-maven3-plugin` 설정 자체가 잘못된 문법(`<property name=... value=.../>`)이라 빌드가 즉시 실패 → `<properties><cargo.servlet.port>...` 형식으로 수정.
5. `cargo:run` 단독 실행 시 war 패키징이 빠져 있어 실패 → 스크립트에서 `mvn -DskipTests package org.codehaus.cargo:cargo-maven3-plugin:run`으로 변경.
6. 포트 충돌(8080) 문제로 8081로 변경, 루트 컨텍스트(`/`)로 배포되도록 `<deployables><context>/</context></deployables>` 추가. (이 부분은 로컬 전용 설정으로 두고 git에는 커밋하지 않음.)
7. 실제 화면(`/frn/report/smDevcSmartStatistics.do`)을 브라우저로 열어보니 초기화 단계에서 공항 콤보박스 로딩이 실패해 화면이 계속 로딩 상태로 멈춰있는 것을 발견 → 콘솔 확인 결과 `Altibase JDBC 드라이버`가 로드되지 않는 문제(`pom.xml`에 의존성이 통째로 주석 처리되어 있었음). 로컬 `.m2`에 실제로는 다른 좌표(`com.altibase:altibase-jdbc:7.3.0.0.3`)로 설치되어 있는 것을 확인, 로컬 테스트용으로만 활성화.
8. 드라이버를 살려도 `Globals.Url2=jdbc:Altibase://127.0.0.1:1721/...`가 실제로는 접속 불가(내부망/터널 필요) 상태라 이 화면은 로컬에서 DB 연동까지 완전히 재현하기 어렵다는 것을 확인.
9. 사용자 요청으로, DB 연결 없이 엑셀 다운로드 로직만 검증할 수 있는 정적 샘플 테스트 페이지(`test-excel-sample.html`)를 제작 — 실제 운영 JS(Tabulator, ExcelJS, `commonLib.js`)를 그대로 로드하고 하드코딩된 샘플 데이터만 주입.
10. 이 샘플 페이지로 버그 재현(sheetName 주석 처리 → 동일한 TypeError, 다운로드 폴더에 파일 생성 안 됨)과 수정 후 정상 동작(파일 생성 + 시트명 정확히 반영)을 모두 실제로 확인.
11. 최종적으로 실제 버그 수정(sheetName 누락)만 `dev` 브랜치에 직접 커밋. `pom.xml`의 cargo 문법 오류 수정은 이번 세션에서는 커밋하지 않기로 함(사용자가 ".js만 커밋하자"고 결정). 로컬 전용 변경(포트, 컨텍스트, altibase 드라이버, 디버그 스크립트, 샘플 페이지)은 git 미추적 상태로 둠.

## 핵심 결정

- **결정 1:** `pom.xml`의 로컬 전용 dev 설정(포트 8081, 루트 컨텍스트 배포, altibase 드라이버 활성화)은 git에 커밋하지 않고 로컬 워킹 디렉토리에만 남긴다.
  → 이유: altibase 드라이버는 Maven Central에 없는 상용 드라이버라, pom.xml에 커밋하면 그 jar를 로컬 `.m2`에 수동 설치하지 않은 다른 팀원의 빌드가 깨진다. 포트/컨텍스트도 개인 로컬 취향이라 공용 pom을 건드릴 필요 없음.
- **결정 2:** cargo-maven3-plugin의 `<property name=.../>` 문법 오류(진짜 버그, 누구든 `cargo:run` 시도 시 즉시 실패)는 이번 세션에서는 미커밋. 사용자가 "그 오류 수정한 부분(js)만 커밋하자"고 명시적으로 판단 — 스코프를 좁게 유지하는 것을 우선시함.
  → 다음 세션에서 별도로 처리 필요 (아래 "다음 할 일" 참고).

## 배운 것

- Cargo Maven3 플러그인의 `Configuration` mojo는 `Map<String,String> properties` 필드만 받는다. `<property name="key" value="val"/>` 같은 cargo-maven2 시절 문법을 그대로 쓰면 `Unable to parse configuration ... Cannot find 'property' in class ... Configuration` 에러로 즉시 실패한다. 반드시 `<properties><key>val</key></properties>` 형식이어야 한다.
- `cargo:run`을 단독 골(goal)로 실행하면 war 패키징 단계를 거치지 않는다. `mvn package cargo:run`처럼 `package` 페이즈를 먼저 넣어줘야 war가 존재한다.
- Tabulator 6.x는 `new Tabulator(...)` 직후 DOM이 아직 준비되지 않은 상태다. `setColumns`/`setData`를 곧바로 호출하면 `Cannot read properties of null (reading 'firstChild')`가 난다. `table.on("tableBuilt", () => {...})` 안에서 호출해야 안전하다.
- DB(Altibase 등) 연동 없이 프론트 로직만 검증하고 싶을 때, 운영 JS 파일을 그대로 로드하고 하드코딩된 샘플 데이터만 주입하는 정적 HTML 페이지를 만들면 서버/DB 의존성 없이도 실제 라이브러리 동작을 정확히 재현/검증할 수 있다. (embedded Tomcat이 이미 떠 있으면 배포된 exploded 디렉토리에 직접 파일을 복사해서 재빌드 없이 즉시 반영 가능.)

## 문제 & 해결

- **문제:** 스마트기기 이용통계 화면에서 엑셀 다운로드 버튼을 눌러도 아무 반응이 없음.
- **원인:** `smDevcSmartStatistics.js`의 엑셀 다운로드 핸들러가 만드는 `xl` 객체에 `sheetName` 속성이 빠져 있어, `commonLib.js`의 `makeXl()`이 `xl.sheetName.toString()`에서 `Cannot read properties of undefined (reading 'toString')`로 즉시 실패.
- **해결:** `sheetName: '공항별 항공사별 스마트기기 이용통계(월별)'` 한 줄 추가.
  → 이슈: [[issues/smdevc-smart-statistics-excel-download-sheetname-missing]]

- **문제:** 로컬에서 Tomcat이 아예 뜨지 않음 (cargo:run 빌드 실패 → war 없음 → Altibase 드라이버 없음 → DB 접속 불가, 4단 콤보).
- **원인/해결:** [[issues/local-tomcat-cargo-run-setup-broken]] 참고.

## 다음 할 일

- [ ] `pom.xml`의 cargo-maven3-plugin `<property>` → `<properties>` 문법 수정을 별도로 커밋할지 결정 (진짜 버그지만 이번 세션에는 보류됨)
- [ ] Altibase 내부망 접속(127.0.0.1:1721) 터널링 방법 확인 — 실제로 이 화면을 로컬에서 완전히 테스트하려면 필요
- [ ] `.vscode/`, `run-tomcat.sh`, `run-tomcat-debug.sh`를 팀에 공유할지, 개인 전용으로 둘지 결정 (현재 git 미추적)
- [ ] `test-excel-sample.html`은 임시 테스트 파일이므로 정리 필요 (계속 남겨둘지 삭제할지)

## 효과적이었던 프롬프트

```
DB 연결 없이 코드 검토로 마무리 대신 "내가 해볼 수 있게 샘플로 처리해줄 수 있어?" — 이 요청 덕분에 정적
읽기 전용 검토에서 그치지 않고, 실제 라이브러리로 버그 재현 + 수정 확인까지 end-to-end로 검증하게 됨.
```
