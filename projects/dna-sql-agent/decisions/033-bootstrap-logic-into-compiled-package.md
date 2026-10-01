---
type: decision-record
project: dna-sql-agent
date: 2026-08-10
status: accepted
superseded-by: ""
tags: [license, nuitka, obfuscation, refactor]
---

# ADR-033: 서버 부트스트랩 로직을 dna/app 컴파일 패키지로 분리

## 맥락

배포 이미지는 자체 코드(`dna`, `vanna`)를 Nuitka로 `.py→.so` 컴파일하고 `scripts/`는 빌드에서 제외한다([[decisions/027-nuitka-source-compilation]]). 그런데 실제 엔트리포인트 `src/main.py`(1592줄)는 최상위에 있어 **컴파일 대상이 아니며 평문으로 이미지에 실린다.** 이 안에 라이선스 워치독·기동 게이트(`require_server_startup_ready`)·컬렉션 러너 오케스트레이션이 통째로 노출돼 있어, 고객이 검사 몇 줄만 지우면 라이선스 강제를 무력화할 수 있다. (위조보다 쉬운 우회로)

## 선택지

### 옵션 A: main.py를 shim으로 축소하고 로직을 dna/app으로 이동
- **장점:** `dna/` 아래라 기존 `find dna vanna` 글롭에 자동 포함 → `.so` 컴파일·난독화. Dockerfile 수정 불필요. 엔트리 경로(`python src/main.py`) 유지.
- **단점:** 파일 분할로 공용 헬퍼(`_utcnow`, `_env_flag`) 소속 정리 필요. `uvicorn main:app` CLI 문자열은 못 쓰게 됨(프로덕션 미사용이라 무관).
- **비용/노력:** 낮음 (함수 위치 이동, 동작 불변)

### 옵션 B: main.py에 Nuitka standalone/개별 컴파일을 별도 지정
- **장점:** 파일 구조 유지
- **단점:** 엔트리 스크립트라 `--module` 방식과 안 맞고 빌드 파이프라인 특례 필요. 최상위 단일 파일 컴파일은 Nuitka 취급이 번거로움.
- **비용/노력:** 중

## 결정

**옵션 A를 선택한다.** `src/main.py`(8줄 shim) → `src/dna/app/` 패키지(`factory`/`lifecycle`/`license_watchdog`/`collection_supervisor`/`cli`/`runtime`).

## 근거

- `dna/` 서브패키지는 기존 빌드 글롭이 자동으로 컴파일하므로 하드닝 이득이 **Dockerfile 변경 0**으로 확보됨
- 함수 이름·본문을 그대로 옮겨 동작 변화 없음 (앱 조립·라우트 192개·startup/shutdown 핸들러 검증)

## 결과

- 라이선스 강제 로직이 `.so`로 컴파일되어 평문 삭제식 무력화가 어려워짐 (단, 근본 위조 방어는 아님 — [[knowledge/patterns/symmetric-mac-verifier-can-forge]])
- `uvicorn`으로 직접 띄우려면 `uvicorn dna.app.factory:app` (엔트리는 여전히 `python src/main.py`)
- PR #138

## 참고 자료

- [[decisions/027-nuitka-source-compilation]]
- [[decisions/028-image-build-context-minimization]]
- [[sessions/2026-08-10-license-forgery-analysis-and-bootstrap-refactor]]
