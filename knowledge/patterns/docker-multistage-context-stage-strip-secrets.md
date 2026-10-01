---
tags: [docker, security, multistage, build]
related: []
---

# Docker 멀티스테이지 — 버려지는 컨텍스트 스테이지로 민감 파일 완전 제거

## 문제

빌드에는 필요하지만(예: `requirements.txt`, 사내 스크립트, 임시 인증 파일) 최종 배포 이미지엔
흔적도 남기면 안 되는 파일이 있을 때, `.dockerignore`는 못 쓴다 — 빌드 컨텍스트 전체에
적용되므로 builder 스테이지의 필수 `COPY`까지 같이 깨진다. 그렇다고 최종 스테이지에서
`COPY` 후 `RUN rm`을 해도, **Docker 이미지는 레이어 누적 구조**라 이전 레이어에 파일이 그대로
남아 `docker save` 후 레이어를 까보면 삭제한 파일을 그대로 추출할 수 있다. 즉 겉보기엔 지워진
것 같아도 보안 목적은 달성되지 않는다(false sense of security).

## 해법

multi-stage 빌드에서 **최종 이미지에 포함되지 않는 스테이지는 통째로 버려진다**는 성질을
이용한다. 파일을 복사하고 걸러내는 작업을 별도의 중간 스테이지에서 수행하고, 최종 스테이지는
그 결과만 `COPY --from=<stage>`로 가져온다.

```dockerfile
# 민감 파일을 거를 중간 스테이지 — 최종 이미지 매니페스트에 절대 포함 안 됨
FROM python:3.10 AS context
WORKDIR /ctx
COPY . .
RUN rm -f requirements.txt some-internal-script.sh

FROM python:3.10
...
COPY --from=context /ctx $HOME/
```

`context` 스테이지에서 지운 파일은 그 스테이지의 레이어에만 존재하고, 최종 이미지는
`context` 스테이지의 최종 결과(파일이 이미 지워진 상태)만 참조하므로 레이어 히스토리
어디에도 원본이 남지 않는다.

## 언제 쓰나

- `.dockerignore`로는 못 거르는데(빌드 필수 파일이라서) 최종 이미지엔 절대 남으면 안 되는 파일
- 이미 있는 `COPY . $HOME/` 같은 "전체 복사" 패턴을 유지하면서 특정 파일만 완전히 배제하고 싶을 때

## 주의

- `.dockerignore`로 처리 가능한 것(런타임에 아예 안 쓰는 `docs/`, `.git/`, 테스트 등)은
  굳이 이 패턴을 안 써도 됨 — `.dockerignore`가 더 단순하고 빌드 컨텍스트 전송량도 줄여줌
- 이 패턴은 "빌드엔 필요하지만 최종엔 안 남아야 하는" 경우에만 쓰는 게 적절

## 관련 페이지

- [[projects/dna-sql-agent/decisions/028-image-build-context-minimization]]
