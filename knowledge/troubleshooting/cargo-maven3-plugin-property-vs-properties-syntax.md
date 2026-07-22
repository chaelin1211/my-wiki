---
type: troubleshooting
project: general
date: 2026-07-15
resolved: true
root-cause: "cargo-maven2 시절 <property name=.../> 단수 문법을 cargo-maven3-plugin의 Configuration mojo(Map 필드)에 그대로 사용"
related: []
tags: [maven, cargo-maven3-plugin, tomcat, jetty]
---

# cargo-maven3-plugin — "Cannot find 'property' in class ... Configuration" 빌드 실패

## 증상

```
[ERROR] Failed to execute goal org.codehaus.cargo:cargo-maven3-plugin:X.X.X:run (default-cli) on project ...:
Unable to parse configuration of mojo org.codehaus.cargo:cargo-maven3-plugin:X.X.X:run for parameter property:
Cannot find 'property' in class org.codehaus.cargo.maven3.configuration.Configuration -> [Help 1]
```

## 환경

- **OS:** macOS (범용, OS 무관)
- **런타임:** Maven 3.9.x, cargo-maven3-plugin 1.10.7 (embedded/standalone tomcat 등)
- **관련 패키지:** `org.codehaus.cargo:cargo-maven3-plugin`
- **재현 조건:** `pom.xml`의 `<configuration><configuration><property name="..." value="..."/></configuration></configuration>` 형태로 서버 프로퍼티를 설정했을 때

## 시도한 것들

1. ✅ 로컬 `.m2`에 캐시된 `cargo-maven3-plugin-*.jar`에서 `org/codehaus/cargo/maven3/configuration/Configuration.class`를 `javap`로 디컴파일해서 실제 setter를 확인
   ```
   public java.util.Map<java.lang.String, java.lang.String> getProperties();
   public void setProperties(java.util.Map<java.lang.String, java.lang.String>);
   ```
   → `property`(단수) 필드는 존재하지 않고 `properties`(복수, Map)만 있음.
2. ✅ XML을 Map 바인딩 형식으로 수정하니 정상 파싱됨.

## 근본 원인

cargo-maven2-plugin 시절(또는 다른 예제/블로그) 문법인 `<property name="key" value="val"/>` 반복 형태와, cargo-maven3-plugin이 실제로 기대하는 `Map<String,String>` 바인딩 형식(`<properties><key>val</key></properties>`)을 혼동해서 생기는 문제. Maven의 plexus 설정 바인더는 `Configuration` 클래스의 필드/setter 이름을 그대로 XML 태그명으로 매칭하기 때문에, 클래스에 없는 `property`라는 태그를 쓰면 즉시 실패한다.

## 해결 방법

```xml
<plugin>
    <groupId>org.codehaus.cargo</groupId>
    <artifactId>cargo-maven3-plugin</artifactId>
    <version>1.10.7</version>
    <configuration>
        <container>
            <containerId>tomcat8x</containerId>
            <type>embedded</type>
        </container>
        <configuration>
            <properties>
                <cargo.servlet.port>8080</cargo.servlet.port>
                <!-- 여러 개면 그냥 <키>값</키> 형태로 계속 추가 -->
            </properties>
        </configuration>
    </configuration>
</plugin>
```

## 예방책

- cargo-maven3-plugin 설정을 작성/복붙할 때는 반드시 3.x 공식 문서(또는 실제 플러그인 jar의 mojo 클래스)를 기준으로 삼는다. cargo-maven2-plugin 예제를 그대로 가져오면 이런 필드명 불일치가 잘 난다.
- 빌드 실패 메시지에 `Cannot find 'X' in class Y`가 뜨면, 항상 `javap`나 IDE로 그 mojo 클래스의 실제 필드/setter를 까보는 게 문서 뒤지는 것보다 빠르다.

## 관련 페이지

- [[projects/kacportal/issues/local-tomcat-cargo-run-setup-broken]]
