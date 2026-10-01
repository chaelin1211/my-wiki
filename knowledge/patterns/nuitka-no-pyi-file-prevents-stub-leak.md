---
tags: [nuitka, python, security, compilation]
related: []
---

# Nuitka `--no-pyi-file` — `.pyi` 스텁을 통한 소스 유출 차단

## 문제

Nuitka로 `--module` 컴파일하면 `.so` 옆에 IDE 자동완성/암시적 임포트 탐지용 `.pyi` 스텁이
자동 생성된다(Nuitka 공식 설명: "This is used to detect implicit imports", "They expose
your API"). 함수 본문 로직은 `.so`로 안전하게 컴파일되어 숨겨지지만, `.pyi`는 다음을
**원문 그대로** 보존한다:

- 함수/클래스 시그니처, 독스트링
- **리터럴 기본 인자값** (`def f(q: str = "SELECT ...")`)
- **모듈/클래스 최상단 상수** (`SYSTEM_PROMPT = "..."`, `SCHEMA_SQL = "CREATE TABLE..."`)

즉 소스 보호 목적으로 컴파일했는데, 프롬프트 템플릿·DB 스키마 DDL·설정값처럼 모듈
상수로 빼둔 것들이 옆에 나란히 놓인 평문 `.pyi` 파일을 통해 그대로 새어나간다.

## 해법

```dockerfile
python -m nuitka --module --remove-output --no-pyi-file --output-dir="..." "$f"
```

`--no-pyi-file`을 주면 `.pyi` 생성 자체를 하지 않는다.

## 헷갈리기 쉬운 옵션: `--no-pyi-stubs`

이름이 비슷하지만 동작이 다르다.

| 옵션 | 동작 |
|---|---|
| `--no-pyi-file` | `.pyi` 파일 생성을 아예 안 함 |
| `--no-pyi-stubs` | `.pyi`는 만들되, stubgen(mypy 도구) 기반 생성 방식만 끔 — Nuitka 자체 내장 방식으로 여전히 `.pyi`가 생성됨 |

유출 차단이 목적이면 반드시 `--no-pyi-file`을 써야 한다. `--no-pyi-stubs`만 쓰면 문제가
그대로 남는다.

## 남는 한계

`--no-pyi-file`은 "파일 열면 바로 읽히는" 가장 쉬운 경로만 막는다. 문자열 상수는 컴파일해도
`.so` 바이너리의 데이터 세그먼트에 그대로 남아 `strings out.so | grep <키워드>`로 추출
가능하다(더 번거로울 뿐 막힌 건 아님). 진짜 민감한 상수(DB 스키마, 프롬프트 등)를 보호하려면
데이터 파일 분리 + 런타임 복호화가 필요하다.

## 확인 방법

```bash
python3 -m nuitka --help | grep -i -A2 pyi
```

옵션 이름을 추측하지 말고 실제 `--help`로 정확한 동작을 확인할 것.

## 관련 페이지

- [[projects/dna-sql-agent/decisions/027-nuitka-source-compilation]]
