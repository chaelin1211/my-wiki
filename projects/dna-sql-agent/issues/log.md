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
- 2026-10-08 띄어 쓴 영어 검색어("sales report", "list of")가 대화 검색에서 0건 → 검색어 공백을 모두 지우고 한글 옆에만 `\s*`를 넣는 규칙이라 영어 단어가 붙어 버림. 검색어에 띄어 쓴 자리에도 `\s*` 허용(백엔드 #175 `25c7f14`, 웹 #100 `0eee752`). 붙여 쓴 영어 검색어로 띄어 쓴 본문 찾기는 미결
- 2026-10-08 대화 검색창에 시스템 내부 이름이 그대로 노출 → 검색 결과에 커넥션 이름이 없어 채팅 목록처럼 `(connection_name, system_name)` 쌍으로 표시명을 찾을 수 없었음. 검색 결과에 `connection_name` 추가 후 같은 `getSystemDisplayName` 사용(백엔드 #175 `f36f804`, 웹 #100 `ddb9c0f`)
- 2026-10-08 지도에 `전남광주통합특별시` 데이터가 표시되지 않음 → 경계 데이터가 통합(2026-07-01) 이전 기준. 전라남도 별칭으로 붙이면 광주 자리가 구멍으로 남아(전남 폴리곤이 광주를 비운 도넛 모양) 전남 폴리곤의 구멍을 메운 통합시 폴리곤을 따로 추가, 옛 광주·전남과 공존(#176 `0030c3f`)
- 2026-10-08 대시보드 위젯 새로고침이 실패해도 표시 없이 예전 차트·예전 시각 유지 → 웹 `catch {}` 로 오류 무시, 백엔드는 데이터 변경도 500. 실패 원인 구분(`CONNECTION_FAILED`·`QUERY_FAILED`·`CHART_MISMATCH`, 원문은 로그만) + 새로고침 아이콘 `!` 툴팁·테두리 강조(#176 `0975a40`, 웹 #101 `34ee8ad`)
- 2026-10-12 위젯 새로고침 툴팁이 hover해도 `!` 가 안 사라지거나 깜빡이며 사라짐 → 강제로 열어 둔 Radix 툴팁의 hover·자기 닫힘·가장자리 pointerleave 문제. 열림을 버튼 hover·focus로만 정하고 툴팁에 `pointer-events-none`(웹 #101 `b5dd54b`) → [[knowledge/troubleshooting/radix-tooltip-forced-open-hover]]
- 2026-10-19 72바이트 넘는 비밀번호(한글 약 25자)로 가입·변경·로그인 시 500 → bcrypt 5.0이 초과 입력에 예외. 새 비밀번호 72바이트 제한 + 확인은 앞 72바이트 비교(백엔드 `8133efc`, 웹 `f8567ab`) → [[knowledge/troubleshooting/bcrypt-72-byte-limit]]
- 2026-10-19 가입일 정렬 추가 후 사용자 목록 API `column "joined_at" does not exist` → ORDER BY 식 안에서 별칭 사용. 계산식을 직접 넣음(백엔드 `5cf2d94`), 가짜 DB 테스트로는 못 잡아 실제 DB로 함수 호출해 확인 → [[knowledge/troubleshooting/postgres-order-by-alias-in-expression]]
- 2026-10-19 승인·거절 기록 SQL에서 asyncpg `inconsistent types deduced for parameter $1` → 같은 `$1` 을 `status = $1` 과 `CASE WHEN $1 = ...` 에 사용. `$1::varchar` 로 명시
- 2026-10-19 생년월일 칸에 없는 날짜(11월 31일 등)를 넣으면 화면엔 날짜가 보이는데 버튼이 안 켜지거나, 선택 항목이면 "생년월일 없음"으로 저장 → 브라우저가 값을 빈 문자열로 넘김. 회원가입·마이페이지는 제출 시 `validity.badInput` 확인(웹 `adb6faf`) → [[knowledge/troubleshooting/html-date-input-invalid-date-empty-value]]
- 2026-10-19 초기화 요청 버튼을 날짜 없이도 켜 두자 엔터로 바로 제출 → 버튼이 꺼져 있으면 브라우저가 엔터 제출을 막던 동작이 사라짐. 생년월일 방식은 값 있을 때만 활성화로 되돌리고 초기화 요청 화면은 모든 칸 엔터 제출 막음(웹 `52c78af`)
- 2026-10-19 초기화 요청 이력에 확정되지 않은 "90일 보관"을 정책처럼 넣음 → 제안만 했던 값을 구현. 삭제 코드·문구·매뉴얼 모두 제거, 보관 정책은 미정으로 남김
- 2026-10-19 Altibase 한글 컬럼명 원인을 `SQL_WMETADATA` 디코딩 누락으로 가정하고 수정 → 영문은 원래 정상이라 모순, 되돌린 뒤 실서버 `cursor.description` 원본을 코드포인트로 확인하고 확정
- 2026-10-19 맥 전용 설정(`PIP_CFLAGS`, CPU판 torch)을 공용 `Dockerfile.local`에 넣음 → 공용은 Altibase 클라이언트 설치만 남기고 개인 `Dockerfile.local.mac`(`.git/info/exclude`)로 분리
- 2026-10-19 수정 전 비교용 이미지 빌드가 pip 캐시를 못 탐 → 중간에 추가한 CPU판 torch RUN 줄 때문에 레이어 무효화
- 2026-10-20 task 모드 lease 오류를 분석하며 "같은 시스템 동시 요청 시 작업 중복 생성"이라고 판단 → 작업 생성 트랜잭션이 `pg_advisory_xact_lock('sql_collection:{system_id}')`로 이미 직렬화, 문서에서 정정
- 2026-10-20 "죽은 수집 작업은 수동 취소 전까지 영구 409"라고 판단 → 수집 시작 시 600초 넘은 running을 자동 마감(`_recover_stale_active_collection_jobs_for_system`), 최대 10분만 막힘
- 2026-10-20 "기동 시 정리는 600초 기준"이라고 `lifecycle.py`만 보고 판단 → 실제 배포 경로 `main.py`는 orphan grace 60초 기준
- 2026-10-20 "수집 시작이 실패하면 다 200"이라고 과장 → 404·409·503은 정상 오류 코드, 예상 밖 예외만 200 + `status: "error"`
- 2026-10-20 ADR을 050번으로 만들었는데 10-19 세션의 `050-dna-ask-link-render-normalization`과 번호가 겹침 → 새 ADR 전에 `decisions/`의 최대 번호를 직접 확인, 052로 변경
- 2026-10-21 메모리 컬렉션을 `scroll(limit=200)` 한 번만 보고 "메모리가 비어 있다", "같은 질문은 1건만 저장"이라고 단정 → 실제 1,143건·3건 중복, 끝까지 페이지 넘겨 세야 함
- 2026-10-22 회귀 비교로 `tests/admin` 전체를 돌려 `license_files/license.json`이 또 테스트 값으로 덮어써짐 → `license.key`로 복구, 이후 `--ignore=tests/admin/test_license.py`와 라이선스 파일 해시 확인으로 실행
- 2026-10-22 일부 파일만 stash하려던 `git stash push -- <경로>`가 없는 경로 때문에 오류를 내면서 전체 변경이 stash로 들어감 → stash 목록으로 확인 후 복원, 경로 지정 stash 대신 커밋 시점 파일을 직접 만들어 나눠 커밋
- 2026-11-03 데이터 구조 검색이 한글 테이블명을 `Invalid table identifier`로 거부 → 영문 전용 식별자 정규식, 유니코드 허용·따옴표 벗기기·재시도 금지 안내
- 2026-11-03 마스킹 `SELECT *` 확장이 한글 컬럼명을 깨진 채 넣어 42S22, 한글 규칙은 마스킹이 조용히 빠짐 → 확장 컬럼명에 복원 미적용, 복원·NUL 정리·비식별자 이름 따옴표
- 2026-11-03 값 프로파일이 화면에서 제외한 테이블까지 스캔(L4 실패 로그로 확인) → 화면은 `스키마.테이블` 저장, 프로파일은 테이블명만 비교. `should_skip_table`로 통일, 남은 트리플은 재생성 시 나눠 삭제
- 2026-11-03 서버 컨테이너 안에서 임베딩 모델을 별도 프로세스로 올리다 OOM으로 서버 종료 → 무거운 실험은 별도 컨테이너에서, 메모리 여유 먼저 확인
- 2026-11-03 중단된 회귀 확인 명령이 `git stash`까지 실행돼 커밋할 변경이 사라진 것처럼 보임 → stash 목록 확인 후 복원
- 2026-11-03 `origin/main`에서 만든 브랜치가 main을 추적한 채 push해 커밋 13개가 리뷰 없이 원격 main에 반영 → `--no-track`으로 생성, push 대상 명시 (사용자 결정으로 유지)
- 2026-11-04 `git fetch` 실패로 `&&` 뒤 브랜치 생성이 실행 안 됐는데 만들었다고 보고 → 연결 명령은 각 단계 결과를 확인하고 보고
