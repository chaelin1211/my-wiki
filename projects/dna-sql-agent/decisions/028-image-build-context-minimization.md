---
type: decision-record
project: dna-sql-agent
date: 2026-07-28
status: accepted
superseded-by: ""
tags: [docker, security, build]
---

# ADR-028: 배포 이미지 빌드 컨텍스트 최소화 및 민감 파일 격리

## 맥락

`Dockerfile`에 `.dockerignore`가 없었고, 최종 스테이지의 `COPY . $HOME/`가 레포 루트 전체
(`docs/`, `.git/`, 테스트, `requirements.txt` 등)를 그대로 배포 이미지에 담고 있었다.
[[decisions/027-nuitka-source-compilation]]으로 자체 소스(`dna`, `vanna`)는 이미 보호했지만,
그 외 문서·설정·의존성 목록이 이미지 안에 그대로 노출되는 문제는 남아있었다.

## 선택지

### 옵션 A: `.dockerignore`로 전부 제외
- **장점:** 설정 한 곳에서 관리, 별도 스테이지 불필요
- **단점:** 빌드 컨텍스트 전체에 적용되므로, builder 스테이지가 필요로 하는 파일
  (`requirements.txt` 등)까지 같이 빠지면 빌드 자체가 깨짐
- **비용/노력:** 낮음

### 옵션 B: 최종 스테이지에서 `COPY` 후 `RUN rm`
- **장점:** 구현 간단, `.dockerignore` 없이도 최종 이미지 파일 목록에서 즉시 사라짐
- **단점:** Docker 레이어는 누적 구조라 이전 레이어에 파일이 그대로 남음 — `docker save` 후
  레이어를 까보면 삭제한 파일도 추출 가능. 보안 목적(민감 파일 완전 제거)엔 미달
- **비용/노력:** 낮음

### 옵션 C: 버려지는 중간 스테이지(`AS context`)에서 걸러낸 뒤 최종 스테이지는 `COPY --from=context`만 사용
- **장점:** multi-stage 빌드는 최종 이미지에 포함되지 않는 스테이지를 통째로 버리므로,
  중간 스테이지에서 지운 파일은 최종 이미지 레이어 히스토리 어디에도 남지 않음. 진짜 완전 제거
- **단점:** 스테이지 하나 추가로 Dockerfile 복잡도 소폭 증가
- **비용/노력:** 낮음~중간

## 결정

**런타임에 전혀 안 쓰는 것(`docs/`, `.git/`, 테스트 등)은 옵션 A(`.dockerignore`)로,
빌드에는 필요하지만 최종 이미지엔 흔적도 남기면 안 되는 것(`requirements.txt` 등)은
옵션 C(버려지는 컨텍스트 스테이지)로 처리한다.**

## 근거

- `.dockerignore`는 빌드 컨텍스트 전송량도 줄여주고 설정이 단순해 "아예 필요없는 것" 처리엔
  최적. 단, 빌드 필수 파일에는 절대 못 씀(전 스테이지 공통 적용이라서).
- "빌드엔 필요하지만 최종 이미지엔 안 남아야 하는" 파일(의존성 목록, 사내 스크립트 등)은
  `.dockerignore` 대상이 될 수 없으므로, 레이어 히스토리까지 안 남기려면 옵션 C가 유일한
  실질적 해법.
- 옵션 B는 겉보기엔 지워진 것처럼 보여도 이미지 레이어를 까보면 그대로 나오므로 보안 목적으로는
  기만적(false sense of security) — 채택하지 않음.

## 결과

- `.dockerignore` 신설·커밋(`08a57bb`, `feat/nuitka`) 완료.
- 옵션 C(`requirements.txt`용 `context` 스테이지) 패턴은 설계 확정, 지식 문서화까지 완료했으나
  **실제 `dna-sql-agent/Dockerfile` 적용은 하지 않기로 결정(2026-07-29)**. 재검토 결과
  `requirements.txt`엔 자격증명 없이 패키지명+버전만 있어 노출 리스크가 낮고, 실제로 얻는
  보안 이득 대비 스테이지 추가로 인한 Dockerfile 복잡도 비용이 맞지 않는다고 판단.
  패턴 자체는 다른 파일(진짜 시크릿이 있는 경우)에 필요해지면 재사용 가능하도록 남겨둠.
- 일반화 가능한 패턴이므로 지식 문서화: [[knowledge/patterns/docker-multistage-context-stage-strip-secrets]]
- 영향받는 컴포넌트: `dna-sql-agent/Dockerfile`만 해당, 다른 mobigen 하위 프로젝트에도
  동일 패턴 적용 검토 여지 있음 (특히 `dna-sql-agent-web`도 이미지 빌드 시 동일 점검 필요).

## 참고 자료

- [[decisions/027-nuitka-source-compilation]]
- [[issues/self-hosted-runner-disk-full-buildx-cache]]
