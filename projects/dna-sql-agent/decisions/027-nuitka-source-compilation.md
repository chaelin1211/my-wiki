---
type: decision-record
project: dna-sql-agent
date: 2026-07-24
status: accepted
superseded-by: ""
tags: [docker, deployment, security, nuitka, obfuscation]
---

# ADR-027: 배포 이미지 소스 보호 — Nuitka로 자체 코드만 파일 단위 컴파일

## 맥락

기존 `Dockerfile`은 `COPY . $HOME/`로 소스를 그대로 이미지에 넣고 `python src/main.py`로
실행했다. 이미지를 풀어보면 `dna/`(비즈니스 로직), `src/vanna/`(로컬 커스텀 포크) 아래
`.py` 파일이 평문으로 그대로 노출된다.

같은 목적으로 먼저 PyArmor를 시도한 흔적이 저장소에 남아 있었으나(`dist/`), 정작 핵심
로직인 `dna/`는 빠지고 `vanna`, `evals`만 처리되어 있어 실질적으로 보호되지 않는 상태였다.

**중요한 전제**: Nuitka·PyArmor 등 어떤 컴파일형 난독화 도구도 문자열/숫자 상수까지
숨기지는 못한다(컴파일해도 바이너리 데이터 세그먼트에 그대로 남아 `strings`로 추출 가능).
API 키·시크릿은 애초에 소스에 하드코딩하지 않고 환경변수로 분리하는 게 원칙이며, 이번
결정은 그 원칙을 대체하지 않는다. 여기서 지키려는 건 어디까지나 "로직을 읽기 어렵게"
만드는 것.

## 선택지

### 옵션 A: 전체 standalone 컴파일 (`nuitka --standalone --follow-imports`)
- **장점:** 명령 하나로 끝, 서드파티까지 포함해 통짜 실행 바이너리 생성
- **단점:** `torch`/`transformers` 등 거대 라이브러리까지 통째로 컴파일 시도 → Colima VM
  8GiB(4 CPU)에서도 `gcc` C 컴파일 단계에서 OOM(31분 38초 만에 실패). 애초에 서드파티는
  공개 오픈소스라 지킬 이유도 없음
- **비용/노력:** 빌드 시간·메모리 비용 매우 큼, 실패 반복

### 옵션 B: 자체 코드만 패키지 단위 컴파일 (`--module --include-package=dna`)
- **장점:** 서드파티 제외로 컴파일 범위 축소, 명령 단순
- **단점:** 패키지 전체가 `dna.cpython-*.so` 파일 하나로 뭉쳐져 `Path(__file__).parent`
  기반 데이터 파일(json/md/geojson) 참조 코드가 전부 깨짐
- **비용/노력:** 낮음(빠름)이지만 런타임에서 즉시 실패

### 옵션 C: 자체 코드만 파일 단위 컴파일 (`.py` 1개 → `.so` 1개, 디렉토리 구조 유지)
- **장점:** 서드파티 제외로 빠름(약 5분/473파일), 디렉토리 구조가 원본과 동일하게 유지되어
  `Path(__file__).parent` 기반 데이터 파일 참조가 그대로 동작. `__init__.py`만 예외적으로
  원본 유지(Nuitka가 단독 컴파일 거부 + 내용이 대부분 단순 re-export라 보호 가치 낮음)
- **단점:** 빌드 스크립트가 파일 순회 루프라 다소 복잡. `.so`와 원본 데이터 파일을 rsync로
  정확히 분리해줘야 함(1차 구현에서 필터 순서 실수로 `.pyc` 캐시가 새어나가는 사고 발생 —
  `--include='*/'`가 `--exclude='__pycache__'`보다 먼저 매치되는 rsync 규칙 순서 문제, 규칙
  순서 수정으로 해결)
- **비용/노력:** 중간 — 최초 설계에 시행착오 필요했지만 이후 재사용 가능

## 결정

**옵션 C — 자체 코드(`dna`, `vanna`)만 파일 단위로 컴파일한다.**

서드파티 패키지(`torch`, `pandas`, `mariadb`, `igraph` 등)는 그대로 pip 설치하고,
`src/main.py`도 배선 코드 위주라 우선순위 낮음으로 판단해 컴파일 대상에서 제외했다.

## 근거

- 지킬 가치가 있는 건 우리 비즈니스 로직뿐 — 서드파티는 이미 공개된 코드라 컴파일해도
  얻는 보안 이득이 없고, 오히려 빌드 실패 위험과 시간만 늘어남(옵션 A 실측)
- 파일 단위 컴파일은 디렉토리 구조를 보존해 기존 코드(`Path(__file__).parent` 패턴)를
  전혀 수정하지 않고 적용 가능 — 애플리케이션 코드 변경 없이 빌드 파이프라인만으로 해결
- `python src/main.py` 실행 방식을 유지해, 로컬 `src/vanna`가 `sys.path[0]` 우선순위로
  pip 설치된 `vanna` 패키지보다 먼저 로드되는 기존 동작(우리가 커스터마이징한 포크가
  실제로 쓰이는 버전)도 그대로 보존됨

## 결과

- 빌드 시간 약 10~11분 (멀티스테이지: builder에서 컴파일, 최종 스테이지는 `dna`/`vanna`
  디렉토리만 컴파일 산출물로 교체)
- 최종 이미지에 원본 `.py`, `.pyc`/`__pycache__` 없음 — 컴파일된 `.so`와 `__init__.py`
  (원본), 데이터 파일(json/md/geojson)만 존재
- 실기동 검증 완료: `.env` 기반 컨테이너 기동 시 `Application startup complete`,
  `/docs`·`/openapi.json` HTTP 200 확인
- 향후 `main.py`도 같은 방식(파일 단위 컴파일 루프에 포함)으로 보호 범위를 넓힐 수 있음
- self-hosted GitHub Actions 러너에서 빌드 시 메모리 여유를 사전 확인해야 함(로컬 검증은
  Colima 8GiB 기준)
- Nuitka·컴파일 방식으로는 상수(API 키 등) 노출을 막을 수 없다는 한계는 여전히 유효 —
  민감 값은 계속 환경변수/시크릿 매니저로 분리해서 관리해야 함
- **추가(2026-07-29):** `--module` 컴파일 시 Nuitka가 자동 생성하는 `.pyi` 스텁이 함수
  기본 인자값·모듈/클래스 상수를 원문 그대로 보존해 `schema.py`(DB DDL),
  `vectorization/prompts.py`(LLM 프롬프트) 등이 새는 걸 발견. `--no-pyi-file` 옵션으로
  `.pyi` 생성 자체를 차단해 이 경로는 막음. 단 `.so` 바이너리 안 문자열은 여전히 `strings`로
  추출 가능 — 진짜 민감한 상수는 별도 데이터 파일 분리+암호화가 필요하며 아직 미결정.
  → `docs/nuitka-build-design.md` §3.4, [[knowledge/patterns/nuitka-no-pyi-file-prevents-stub-leak]]

## 참고 자료

- `docs/nuitka-build-design.md` (저장소 내 상세 설계 문서 — 시행착오 전체 기록, Colima
  트러블슈팅, Dockerfile 구조)
- `Dockerfile` (커밋 `f3abe40`, 브랜치 `feat/nuitka`)
