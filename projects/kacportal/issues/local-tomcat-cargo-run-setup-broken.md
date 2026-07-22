---
type: troubleshooting
project: kacportal
date: 2026-07-15
resolved: true
root-cause: "cargo-maven3-plugin pom.xml 설정 문법 오류 + war 패키징 누락 + Altibase 드라이버 의존성 비활성화 (3단 연쇄)"
related: [smdevc-smart-statistics-excel-download-sheetname-missing]
tags: [maven, cargo-maven3-plugin, tomcat, altibase, local-dev-environment]
---

# 로컬에서 VS Code로 Tomcat 디버그 실행이 전혀 안 됨

## 증상

`.vscode/launch.json`/`tasks.json`은 이미 구성되어 있었지만 "Tomcat Debug (Auto Start)"를 실행해도 아무 일도 일어나지 않거나 계속 에러. 원인이 여러 겹이라 하나씩 벗겨내야 했음.

## 환경

- **OS:** macOS
- **런타임:** Java 8 (corretto-1.8.0), Maven 3.9.10, cargo-maven3-plugin 1.10.7 (embedded tomcat8x)
- **관련 패키지:** `pom.xml`, `.vscode/tasks.json`, `.vscode/launch.json`
- **재현 조건:** 로컬에서 `mvn cargo:run` 또는 VS Code 디버그 버튼 실행 시 100% 재현

## 시도한 것들

1. ✅ `run-tomcat.sh`/`run-tomcat-debug.sh`가 tasks.json에서 참조되지만 실제 파일이 없음을 발견 → 새로 작성 (`mvn ... org.codehaus.cargo:cargo-maven3-plugin:run`, JDWP는 `MAVEN_OPTS`에 `-agentlib:jdwp=...address=5006` 추가)
2. ✅ 실행하니 `pom.xml`의 cargo 설정에서 `Unable to parse configuration ... Cannot find 'property' in class org.codehaus.cargo.maven3.configuration.Configuration` 에러 → jar 안의 `Configuration.class`를 `javap`로 까보니 `Map<String,String> properties` 필드만 있고 `property`(단수)는 없음. `<property name="cargo.servlet.port" value="8080"/>` 문법 자체가 틀렸던 것.
3. ✅ `<properties><cargo.servlet.port>8080</cargo.servlet.port></properties>`로 수정 → 다음 에러: `Failed to find file [.../target/sht_webapp.war]` (war가 없음)
4. ✅ `cargo:run`을 단독 goal로 실행하면 `package` 페이즈를 안 거침 → 스크립트를 `mvn -DskipTests package org.codehaus.cargo:cargo-maven3-plugin:run`으로 변경, 빌드+war+embedded tomcat 기동까지 성공 (포트 8080)
5. ✅ 포트 8080이 이미 사용 중(같은 세션에서 이전에 띄운 프로세스가 안 죽어서)이라 8081로 변경, 동시에 `<deployables><deployable><properties><context>/</context></properties></deployable></deployables>`를 추가해 `/sht_webapp` 대신 루트(`/`)로 배포
6. ✅ 화면 진입 시 공항 콤보박스 로딩이 멈춤 → 콘솔에서 `bindCombo`가 `undefined.length`로 죽는 것 확인 → `fetchCombo` API(`/frn/report/getBiData.do`)가 `code: 8888`(서버 예외) 반환 → 톰캣 로그에서 `Cannot load JDBC driver class 'Altibase.jdbc.driver.AltibaseDriver'` 확인
7. ✅ `pom.xml`에서 altibase 드라이버 의존성이 통째로 주석 처리되어 있던 것을 발견. 로컬 `.m2`에는 이미 실제로 다른 좌표(`com.altibase:altibase-jdbc:7.3.0.0.3`)로 설치되어 있어서 그 좌표로 활성화 → 드라이버 클래스 로드 문제는 해결
8. ⚠️ 드라이버를 살려도 `Globals.Url2=jdbc:Altibase://127.0.0.1:1721/...`가 실제로 접속 불가(`nc -z 127.0.0.1 1721` 실패) → 내부망 Altibase에 대한 로컬 터널/VPN이 없으면 이 부분은 근본적으로 해결 안 됨 (환경 한계, 코드 문제 아님)

## 근본 원인

3가지가 겹쳐서 하나씩 안 풀면 다음 단계로 못 넘어가는 구조였음:

1. **cargo-maven3-plugin 설정 문법 오류** (`pom.xml`) — cargo-maven2 시절 문법이 섞여 들어가 있었음. 진짜 버그, 누구든 로컬에서 `cargo:run` 시도하면 100% 실패.
2. **war 패키징 누락** — `cargo:run` 단독 실행은 `package` 페이즈를 자동으로 안 태움. 이건 문법 문제라기보다 실행 방법(스크립트) 문제.
3. **Altibase 드라이버 의존성 비활성화** — 상용 드라이버라 Maven Central에 없어서 의도적으로 주석 처리되어 있었을 가능성 높음. 로컬 `.m2`에 이미 수동 설치되어 있던 좌표와 pom.xml의 주석 처리된 좌표가 서로 달랐음(`altibase:altibase-jdbc-driver:5.1.3.18` vs 실제 `com.altibase:altibase-jdbc:7.3.0.0.3`).

## 해결 방법

```xml
<!-- pom.xml: cargo-maven3-plugin 설정 (문법 수정, 포트는 예시) -->
<configuration>
    <container>
        <containerId>tomcat8x</containerId>
        <type>embedded</type>
    </container>
    <configuration>
        <properties>
            <cargo.servlet.port>8080</cargo.servlet.port>
        </properties>
    </configuration>
</configuration>
```

```bash
# run-tomcat.sh — package 페이즈 포함해서 실행
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
mvn -DskipTests package org.codehaus.cargo:cargo-maven3-plugin:run
```

Altibase 드라이버는 팀 공용 `pom.xml`에는 커밋하지 않고(다른 팀원 `.m2`에 jar가 없으면 빌드가 깨짐), 로컬 전용으로만 활성화해서 사용.

## 예방책

- `pom.xml`의 cargo 설정 오류는 진짜 버그이므로 언젠가 정식으로 고쳐서 커밋해야 함 (이번 세션에서는 스코프를 좁게 유지하려고 보류함 — [[projects/kacportal/status]] "진행 중" 참고).
- 상용/비공개 JDBC 드라이버는 pom.xml에 커밋하는 대신, README나 팀 위키에 "로컬 `.m2`에 수동 설치가 필요하다"는 안내를 남겨두는 게 낫다.
- DB 연동이 필요한 report 화면을 로컬에서 테스트하려면 Altibase 내부망 터널링 방법을 먼저 팀에 확인해둘 것.

## 관련 페이지

- [[projects/kacportal/issues/smdevc-smart-statistics-excel-download-sheetname-missing]]
- [[projects/kacportal/sessions/2026-07-15-excel-download-sheetname-bug-tomcat-debug-setup]]
- [[knowledge/troubleshooting/cargo-maven3-plugin-property-vs-properties-syntax]]
