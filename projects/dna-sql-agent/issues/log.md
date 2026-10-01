---
type: issue-log
project: dna-sql-agent
---

# 사소한 문제 로그

1회성 실수나 이 프로젝트에 국한된 사소한 문제를 짧게 기록. 재발 가능성이 있거나
다른 프로젝트에서도 참고할 만하면 별도 파일로 승격.

- 2026-07-09 Radix `Tooltip.Arrow`(말풍선 꼬리)에 `border`를 줬더니 삼각형이 아니라 사각형 바운딩 박스 전체에 테두리가 그려짐 → Arrow는 내부적으로 `<svg>`라 CSS border가 실제 폴리곤 모양이 아닌 SVG 요소의 사각 바운딩 박스에 적용됨. 꼬리 테두리는 포기하고 본체 박스에만 `border-border` 유지.
- 2026-07-22 `/me` 응답이 JWT 클레임의 스탈 그룹명을 반환 → 그룹 이동 후 재로그인 전까지 옛 그룹명이 보임. DB 조회로 변경.
- 2026-07-22 멤버 관리 다이얼로그의 `is_admin`이 다른 그룹 관리자에게도 표시됨 → API 스코프 조건이 조회 대상 그룹이 아닌 전체 관리자 기준이었음. 조건 수정.
- 2026-08-04 `.dockerignore` 에 `.env` 를 추가하자 사내 CI 배포가 전부 크래시(`KeyError: 'DB_ENCRYPTION_KEY'`) → 배포는 `.env` 를 마운트하지 않고 **이미지에 구워진 파일**을 읽고 있었음. `config/`·`log/` 만 마운트되는 것을 보고 "런타임 영향 없음"으로 판단한 오판. 워크플로가 체크아웃한 `.env` 를 호스트로 복사·마운트하도록 수정.
- 2026-08-04 외부 DB 를 지정했는데 `InvalidPasswordError` → `init.sh` 가 외부 여부와 무관하게 `DNASQL_AGENT_DB_PASSWORD` 를 랜덤 생성. `DB_MODE=external` 이면 생성하지 않고 입력 요청하도록 변경.
- 2026-08-04 `.env` 수정 후 재기동해도 DB 접속 정보가 안 바뀜 → `.env` 는 최초 기동 시 `config/*.json` 을 만드는 시드일 뿐, 이후에는 JSON 이 우선. `config/database.json` 을 지우고 재기동해야 반영됨.
- 2026-08-04 배포 패키지의 체크섬 파일로 `sha256sum -c` 가 실패 → 절대 경로가 기록되어 고객사에 없는 경로를 찾음. 파일명만 기록하도록 수정.
- 2026-08-05 `.env` 에 `DB_ENCRYPTION_KEY` 가 있는데 `init.sh` 가 "직접 입력하라"고 안내 → 같은 키가 **두 줄** 있었고 앞줄이 빈 값. `grep ... | head -1` 이 빈 값을 집었음. 중복 줄 제거로 `Fernet key must be 32 url-safe base64-encoded bytes` 오류까지 함께 해소.
- 2026-08-05 화면에서 API 요청이 404 → `http://localhost:3000`(웹 컨테이너)으로 직접 접속했기 때문. 번들은 상대 경로로 요청하므로 nginx(80)를 거쳐야 백엔드로 감. 이후 웹 컨테이너의 호스트 포트를 닫아 우회 자체를 차단.
- 2026-08-05 설정 화면이 `Cannot read properties of undefined (reading 'type_weights')` 로 죽음 → `PUT /settings/{id}` 가 부분 body 를 그대로 저장해 `rag.json` 이 `{"enabled": false}` 로 잘림. 프론트는 PUT 을 쓰지 않아 실사용 경로로는 재현되지 않음(파일 직접 편집·API 직접 호출 시 발생).
- 2026-08-05 잘못된 설정값을 PATCH 하면 화면에 사유가 안 뜨고 `TypeError: Failed to fetch` → `ValidationError` 가 그대로 올라가 **CORS 헤더 없는 500** 이 되어 브라우저가 차단. 400/422 변환 필요(미수정).
- 2026-08-05 `docker save` 진행 표시가 계속 `0` → `du -h` 가 1MB 미만을 `0` 으로 찍음. 초반 4분치로 외삽해 "5.7시간" 으로 잘못 추정했으나 실제로는 정상 속도로 붙어 15분 내 완료.
- 2026-08-06 패키징 워크플로에서 "이미지 새로 빌드"를 껐는데도 소스 체크아웃이 실행되어 `Input required and not supplied: token` → `workflow_dispatch` 의 `type: boolean` 입력이 표현식에서 문자열로 들어와 `if: ${{ inputs.x }}` 가 `"false"` 에도 참. 부정형 `!inputs.x` 는 반대로 항상 건너뜀. `github.event.inputs.x == 'true'` 로 명시 비교. → [[projects/dna-sql-agent/issues/github-actions-boolean-input-always-truthy]]
- 2026-08-06 브랜치 변경분에 이미 머지된 Nuitka 작업이 섞여 보임 → 로컬 `main` 이 40커밋 뒤처져 있었음. `origin/main..HEAD` 로 재산정(24커밋).
- 2026-08-06 `requirements.txt` 첫 줄이 `--find-links .../cu118` 인데 실제로는 `nvidia-*-cu12`(PyPI 기본 cu121 휠)가 설치되고 있었음 → `--find-links` 는 우선순위를 강제하지 않음. 인덱스를 고정하려면 `--index-url` 필요.
- 2026-08-10 서버 기동 시 `Unsupported license key format` (만료 에러 아님) → `config/license.json`의 `license_key` 앞에 `111`이 붙어 프리픽스가 `111dadap`. 파싱 단계에서 형식 거부되어 만료 판정 이전에 막힘. 정상 키로 재활성화. (config 단일 소스 구조는 [[projects/dna-sql-agent/issues/license-key-file-not-reapplied-when-config-present]])
- 2026-08-12 `defaults/*.json` 에 넣은 `_` 메타 키가 새로 만들어지는 `config/*.json` 에 그대로 복사됨 → `get_default()` 가 파일을 그대로 반환하고 있었음. `get_default_spec()`(메타 포함)과 `get_default()`(`_strip_meta` 적용)로 분리.
- 2026-08-14 채팅 답변의 금액 표기(`-$0.03 ~ -$10에서`)가 이탤릭 수식으로 깨지고 KaTeX `unicodeTextInMathMode` 경고 → `remark-math` 가 `$` 를 수식 구분자로 보아 짝지음. `remarkMath` 옵션에 `singleDollarTextMath: false` 를 주어 `$$` 블록만 수식으로 취급 (dna-sql-agent-web `7a2b212`).
- 2026-08-14 `enabled: false` 로 끈 도구가 계속 동작 → 도구 등록은 기동 시 1회뿐이고 핫리로드가 재등록하지 않아, 끄기 전 만들어진 객체가 메모리에 살아 있었음. `sync_registered_tools()` 를 hot_reload 에 편입.
- 2026-08-14 관리자 화면에서 쿼리 비용 예측기 임계값을 바꿔도 무반응 → `database_pool` 경로가 `QueryEstimator` 를 자격증명만으로 생성하고 `estimator.json` 을 읽지 않았음(`from_config()` 는 쓰이지 않는 legacy 경로 전용). `apply_config()` 추가 후 생성·호출 양쪽에서 적용.
- 2026-08-14 신규 도구 추가 후 기동하면 아무 조작 없이 미반영 배너가 뜸 → 기동 중 `tool_access.json` 이 두 번 저장(표식 부착·소비)되는데 판정 기준 시각이 모듈 import 시점이었음. `mark_started()` 로 기준을 기동 완료 시점으로 이동.
- 2026-08-20 다중 y 를 절반만 구현해 `y='A,B'` 가 렌더러까지 전달 → 보내는 쪽만 고치고 받는 쪽은 `bar`/`line` 두 분기만 수정, 해석을 함수 상단으로 올리고 타입별 파라미터라이즈 테스트로 고정
- 2026-08-20 미지원 타입 누출 검사 정규식이 `sankey에서는` 을 놓침 → 한글이 `\w` 라 `\b` 경계가 안 생김, `\bsankey(?![A-Za-z])` 로 대체
- 2026-08-25 `.env.production` 에 `MAP_TILE_URL` 을 적었는데 반영이 안 됨 → `npm run dev` 는 `.env.production` 을 읽지 않음(dev 는 `.env.development`·`.env.local`만). 로컬 확인은 `.env.local` 에 적고 개발 서버 재시작
- 2026-08-25 `/code-review` 가 지도 변경 대신 차트 코드를 리뷰함 → 스킬이 현재 작업 디렉터리(백엔드)의 브랜치 diff 를 대상으로 돎. 변경한 저장소에서 실행해야 함

- 2026-09-16 실행 중이던 `next dev`(:3000)가 조용히 죽음 → main 을 당긴 뒤 돌린 `npm ci` 가 `node_modules` 를 통째로 교체했기 때문. 확인용 서버는 빌드 산출물(`.next/standalone`)을 다른 포트로 띄워 사용자 dev 서버와 분리할 것
- 2026-09-16 claude-in-chrome 클릭이 계속 빗나감 → `scale: 0.6` 으로 받은 스크린샷의 좌표를 그대로 넘겼는데 클릭은 원본 해상도 기준. 축소 캡처를 쓸 때는 좌표를 환산하거나, 좌표 대신 JS 로 요소를 찾아 `.click()` 할 것
- 2026-09-21 `/api/v1/commands` 404 → 디버거가 띄우는 진입점이 `src/main.py`인데 라우터를 `dna/app/factory.py`에만 등록함. 진입점이 둘이라 새 라우터는 양쪽에 등록할 것
- 2026-09-21 서버 재시작 후에도 `/help` 버튼 스타일이 안 바뀐 것처럼 보임 → 마지막 `/help`가 재시작 8초 전 옛 코드로 실행·저장된 응답이었음. 저장된 응답은 실행 당시 모양이 남으므로 새로 실행해서 확인
- 2026-09-22 SQL 예제 필터 `ToggleGroup`이 지나치게 큼 → 공통 `ToggleGroupItem`에 항목당 `min-w-24 flex-1`이 있음. 짧은 라벨에는 `min-w-0 flex-none`으로 덮어씀
- 2026-09-22 한국어 토스트가 단어 중간에서 줄바꿈 → 한국어는 기본값이 음절 단위 줄바꿈. `break-keep`(word-break: keep-all) 적용
- 2026-09-22 SQL 예제 화면 `prism-tomorrow.css` import가 앱 전체 Prism 색을 어두운 테마로 바꿈 → 컴포넌트에서 전역 테마 CSS를 import하면 다른 화면까지 번짐. 하이라이트 색은 `globals.css` 공통 규칙으로
- 2026-09-22 `globals.css`에 추가한 규칙이 브라우저 CSS에 없음(파일 재저장·새로고침으로도 CSS 청크 해시 불변) → next dev(Turbopack) CSS 재빌드 누락으로 추정, dev 서버 재시작 필요(미확인)
- 2026-09-22 `/memories`가 한 대화에서는 비고 다른 대화에서는 10건 → 메모리가 대화의 시스템(`database_id`·`system_name`) 기준으로 저장·조회됨. 시스템 범위가 빈 대화는 필터 없이 전체 시스템 메모리를 보여 주는 것으로 보임(원인 미추적)

- 2026-09-22 SQL 예제 AI 생성이 "작업을 처리하지 못했습니다"로 실패 → task 모드 러너(`get_collection_runner`)가 `CollectionRunner()`를 인자 없이 만들어 설정 작업 테이블(`sql_collection_jobs_v2`) 대신 기본 `sql_collection_jobs`를 조회. 설정 테이블 이름 전달로 수정(`7be2643`)
- 2026-09-22 SQL 예제 AI 생성이 오류 없이 "완료 0건" → 대상 DB `shared_preload_libraries`에 `pg_stat_statements` 없음. 수집기가 예외를 로그로만 남기고 빈 목록 반환해 원인이 화면에 안 보임 → [[knowledge/troubleshooting/sql-history-collection-prerequisites]]
