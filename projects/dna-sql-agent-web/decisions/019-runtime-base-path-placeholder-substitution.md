---
type: decision-record
project: dna-sql-agent-web
date: 2026-10-16
status: accepted
superseded-by: ""
tags: [nextjs, basepath, nginx, docker, deployment, reverse-proxy]
---

# ADR-019: 도메인 하위 경로 서비스 — 자리표시자 빌드 + 기동 시 BASE_PATH 치환

## 맥락

LH PoC 고객사가 자기 도메인 아래(`https://도메인/test`)에 리버스 프록시로 DaDap 을 붙이기로 함.
브라우저 주소는 `~~/test` 로 유지되는데, Next 가 내려주는 HTML·JS 의 경로(`/_next/...`,
`/api/...`, `/chat`)가 `/test` 밖으로 나가 프록시를 타지 못하고 404.

제약:
- Next `basePath` 는 **빌드 타임 값**(결과물에 문자열로 박힘). 공식 런타임 basePath 없음.
- 설치 패키지(`dna-sql-agent-deploy`)는 고객사에 **빌드된 이미지**를 주고 `.env` 만 고쳐 기동하는
  구조 — 현장 재빌드 불가.
- 같은 웹 이미지를 GitHub Actions(dev·linko·mobigen) 배포에도 씀. (2026-10-29 mobigen → monaco 이름 변경)
- 앞단 프록시가 `/test` 를 **떼고 넘기는지 붙여 넘기는지 알 수 없음**.

## 선택지

### 옵션 A: 고객사별 빌드 (build-arg 로 basePath 지정)
- **장점:** Next 정식 기능, 깨질 일 없음. `package.sh` 의 사이트 `env.overlay` 로 몇 줄이면 됨
- **단점:** 경로를 바꾸려면 재패키징. 현장에서 `.env` 로 변경 불가
- **비용/노력:** 낮음

### 옵션 B: 자리표시자로 빌드 → 기동 시 치환
- **장점:** 이미지 한 벌. 배포 방식과 무관하게 `BASE_PATH` 환경변수 하나로 경로 결정
- **단점:** 결과물 문자열 치환이라 Next 업그레이드로 basePath 인코딩 방식이 바뀌면 누락 가능
- **비용/노력:** entrypoint 스크립트 1개 + 검증

### 옵션 C: nginx `sub_filter` 로 응답 본문의 경로 치환
- **장점:** 웹 재빌드 불필요
- **단점:** Next 번들 내부에서 런타임에 만드는 경로(청크 로딩·라우터)는 못 고쳐 군데군데 깨짐
- **비용/노력:** 낮음 — 그러나 신뢰 불가

### 옵션 B 의 설정 위치 변형: `.env.production` 을 entrypoint 가 폴백으로 읽기
- Actions 는 `.env.production`, deploy 는 `.env` 로 정하자는 안. 컨테이너에 `BASE_PATH` 가
  "정의돼 있으면(빈 값 포함) 우선, 없으면 파일" 규칙으로 구현까지 했다가 폐기.
- **단점:** 설정 위치 2곳 + 코드를 읽어야 알 수 있는 숨은 우선순위 + 파일 공유라 서버별 지정 불가

## 결정

**옵션 B 를 선택하고, 설정 위치는 컨테이너 `BASE_PATH` 환경변수 하나로 통일한다.**

- 웹 이미지: Dockerfile 빌드 단계에서 `NEXT_PUBLIC_BASE_PATH`·`NEXT_PUBLIC_API_BASE_URL` 을
  `/__DADAP_BASE_PATH__` 로 고정. `docker-entrypoint.sh`(node)가 기동 시 `/app/server.js`·`/app/.next`
  안의 자리표시자를 `BASE_PATH` 로 치환 후 `exec node server.js`.
  - escape 형태 `\\/`·`\/`·`%2F` 도 함께 치환(정규식이 담긴 manifest 대비)
  - 형식 오류(`/` 로 시작·끝 `/` 없음·`[A-Za-z0-9_-]`)나 치환 후 자리표시자 잔존 시 **기동 중단**
  - `BASE_PATH` 미지정 → 빈 값 치환 → 기존과 동일하게 `/`
- 전달 경로
  - GitHub Actions: 저장소 Variables `DEV_/LINKO_/MOBIGEN_BASE_PATH` (현재 `MONACO_BASE_PATH`) → `docker run -e BASE_PATH`
  - 설치 패키지: `.env` 의 `BASE_PATH` → compose `web.environment`
- nginx(웹 레포 `nginx.conf`, deploy `nginx.conf`·`nginx-http.conf`): 공식 이미지 템플릿 기능으로
  `${BASE_PATH}` 채움(`NGINX_ENVSUBST_FILTER=^BASE_PATH`). 앞단이 경로를 떼든 붙이든 받도록
  화면 요청엔 경로를 붙이고 API 요청에선 뗌.
- `.env.production` 의 `NEXT_PUBLIC_BASE_PATH` 는 Docker 없이 `npm run build` 할 때만 쓰임
  (Docker 빌드에서는 Dockerfile `ENV` 가 우선).

## 근거

- "현장에서 `.env` 만 고쳐 경로를 바꿀 수 있어야 한다"를 만족하는 건 B 뿐.
- 치환 누락은 조용히 깨지지 않고 기동 단계에서 드러나도록 막아 둬서, 위험이 "Next 업그레이드 때
  한 번 점검"으로 한정됨. 실패해도 경로 404 수준이지 데이터·보안 문제는 아님.
- 설정 위치를 하나로 두면 deploy·Actions 가 같은 규칙("경로는 컨테이너 `BASE_PATH` 가 정한다")을
  공유하고, Actions 는 GitHub 변수만 바꿔 재배포하면 됨(코드 수정·커밋 불필요).

## 결과

- **Next 업그레이드 시 점검**: `BASE_PATH=/x` 와 빈 값으로 각각 기동해 페이지·`_next` 정적 파일·
  `/x/` 처리를 확인. entrypoint 가 잔존 자리표시자를 알려 주면 그 형태를 `separators` 에 추가.
- 코드에서 `/` 로 시작하는 경로를 직접 쓰면 basePath 가 안 붙음 → `withBasePath()`
  (`lib/base-path.ts`) 필수. 이번에 적용: `next/image` 로고·메타데이터 아이콘·`window.open`
  (매뉴얼·관계도)·`fetch('/map-config')`. `Link`·`router`·서버 `redirect()` 는 자동.
- `.env.production` 의 두 `NEXT_PUBLIC_*` 값은 Docker 빌드에서 무시됨 — 다른 도메인 절대 API 주소를
  쓰는 서버가 생기면 API 주소도 런타임 변수로 열어야 함.
- 영향받는 컴포넌트: Dockerfile·entrypoint, 워크플로 3개, 웹 `nginx.conf`, deploy compose·nginx
  템플릿·`start.sh`(형식 검사·접속 주소 안내)·`.env.template`·`nginx-snippet.conf`(고객사 웹 서버용 예시).
- 서브패스 고유의 한계: localStorage(로그인 토큰 `jwt_auth`)는 도메인 단위라 같은 도메인의 다른
  서비스와 공유됨. 고객사 WAF 가 SQL 이 담긴 요청을 막을 수 있음.
- 실제 빌드 이미지로의 치환 검증은 PR 시점 미완 — 첫 배포 전 확인 필요.

## 참고 자료

- 웹 PR #104 (`feat/base-path`), 태그 `20261016_LH_PoC`
- deploy 커밋 `260590b`(BASE_PATH 지원)·`03824e3`(지도 타일 주소 안내), main 반영
- [[projects/dna-sql-agent-web/decisions/014-multi-server-nginx-reverse-proxy|ADR-014]] — 상대경로 API + nginx 프록시(이번 결정의 전제)
- [[knowledge/tools/nextjs-runtime-base-path]]
- [[knowledge/tools/nginx-docker-envsubst-templates]]
