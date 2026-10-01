---
type: decision-record
project: dna-sql-agent
date: 2026-08-04
status: accepted
superseded-by: ""
tags: [deployment, packaging, security]
---

# ADR-030: 고객사 배포 패키지를 별도 저장소로 분리

## 맥락

소스 접근 없이 타 사이트(고객사)에 제품을 전달해야 한다. 기존 배포는 사내
3개 사이트에 self-hosted runner 로 소스를 체크아웃해 빌드하는 방식이라,
소스를 줄 수 없는 고객사에는 쓸 수 없다.

전달물은 `docker save` 로 만든 이미지 tar 와 설치 스크립트·안내서다. 이걸
어디서 관리할지가 문제였다.

## 선택지

### 옵션 A: 소스 저장소 안에 `deploy/` 디렉토리
- **장점:** 저장소 하나. 버전이 소스와 자동으로 맞음
- **단점:** "여기까지는 줘도 되고 저기부터는 안 된다"를 매번 사람이 판단해야
  한다. 소스 저장소에는 `.env` 시크릿·내부 IP·32개 커밋의 이력이 있어
  통째로 전달할 수 없다
- **비용/노력:** 낮음

### 옵션 B: 배포 전용 저장소 신설
- **장점:** 저장소 전체가 "고객에게 그대로 줘도 되는 상태"로 유지된다.
  경계가 물리적으로 고정되어 사고 지점이 사라진다. 접근 권한도 분리 가능
- **단점:** 저장소가 하나 늘고, 이미지 버전과의 동기화를 사람이 챙겨야 함
- **비용/노력:** 중간

### 옵션 C: Replicated / Zarf 같은 배포 플랫폼 도입
- **장점:** 에어갭 번들·라이선스·설정 UI 등 완성된 기능
- **단점:** 둘 다 Kubernetes 전제. 고객사는 compose 하나면 되는 규모이고
  Replicated 는 유료
- **비용/노력:** 높음

## 결정

**옵션 B** — `DnA-Platform-Development-Team/dna-sql-agent-deploy` (private) 신설.

경계 원칙:

| 소스 저장소 | 배포 저장소 |
|---|---|
| `Dockerfile`, `.dockerignore` | `docker-compose.yml`, nginx 설정 |
| 이미지를 **어떻게 만드는가** | 만들어진 이미지를 **어떻게 운영하는가** |
| `docker-entrypoint.sh` | `init.sh`, `start.sh`, `INSTALL.txt` |

`Dockerfile` 을 소스 저장소에 남긴 이유는 소스 구조(`src/dna`, Nuitka 컴파일
대상, 로그 경로)에 직접 묶여 있어 코드가 바뀌면 같이 바뀌어야 하기 때문이다.

## 근거

- compose 기반 에어갭 배포에는 지배적인 표준 도구가 없다. Replicated·Zarf 가
  실제 제품이지만 K8s 전제라 우리 규모에 맞지 않는다
- 사이트가 늘어날 때 사이트별 값(LLM 주소, 도메인)을 관리할 자리가 필요한데,
  소스 저장소 브랜치로 관리하면 금방 엉킨다

## 결과

- 시크릿은 패키지에 넣지 않고 고객사에서 `init.sh` 가 생성한다.
  `package.sh` 가 압축 직전 gitleaks + 자체 검사로 확인하고, 값이 있으면 중단
- 사이트별 오버레이(`sites/<이름>/`)는 선택이며 평소에는 쓰지 않는다.
  사이트마다 달라지는 값은 대부분 고객이 설치 시점에 입력하기 때문
- 산출물은 `dist/<사이트>/<버전>/<일시>/` 로 쌓아 같은 버전을 다시 말아도
  덮어쓰지 않는다

## 관련

- 세션: [[projects/dna-sql-agent/sessions/2026-08-04-customer-delivery-package]]
- [[projects/dna-sql-agent/decisions/028-image-build-context-minimization]]
- [[projects/dna-sql-agent/decisions/031-container-mount-ownership-entrypoint]]
