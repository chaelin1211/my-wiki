---
type: log
---

# my-wiki — Log

시간순 작업 기록. 각 항목은 `## [YYYY-MM-DD] 유형 | 제목` 형식.

---

## [2026-04-20] init | my-wiki 초기 설정

- Obsidian Vault 생성
- 디렉토리 구조, 템플릿, 스키마 초기화 완료

## [2026-04-20] init | dna-sql-agent 프로젝트 생성

- 위키 프로젝트 폴더 생성: projects/dna-sql-agent
- 목표: 자연어 질문을 SQL로 변환하여 Oracle DB 결과를 반환하는 온프레미스 AI 에이전트
- 스택: python, fastapi, vanna, ollama, oracle-db, qdrant

## [2026-04-20] init | dna-sql-agent-web 프로젝트 생성

- 위키 프로젝트 폴더 생성: projects/dna-sql-agent-web
- 목표: dna-sql-agent 백엔드와 연동하는 Text-to-SQL AI 챗봇 웹 프론트엔드
- 스택: nextjs, typescript, tailwindcss, shadcn-ui, plotly

## [2026-04-20] init | kac-idp-noti 프로젝트 생성

- 위키 프로젝트 폴더 생성: projects/kac-idp-noti
- 목표: Kafka consumer 기반 KAC IDP 알림 발송 서버
- 스택: java, spring, kafka, hibernate, altibase, docker

## [2026-04-20] init | kacportal 프로젝트 생성

- 위키 프로젝트 폴더 생성: projects/kacportal
- 목표: KAC 공항공사 통합데이터플랫폼 포털 웹 애플리케이션
- 스택: java, spring, egovframe, oracle-db, tomcat

## [2026-05-14] session | dna-sql-agent-web — docker --network host 적용 & 시스템 선택 팝업 디버깅

## [2026-05-19] session | dna-sql-agent-web — 마이페이지 커밋/PR 생성, 어드민 인증 가드 추가

## [2026-05-20] session | dna-sql-agent-web — 이전 대화 단순 응답 메시지 누락 버그 수정

## [2026-04-20] session | kacportal — 법령정보 URL 더블 인코딩 픽스 & 공지사항 팝업 내비게이션 수정

- 법령정보 첨부파일 다운로드 URL 더블 프리픽스/더블 인코딩 수정 (`LawSrchController.java`)
- 공지사항 팝업 POST → GET 방식 변경, 내부/외부 링크 분기 추가 (`main.jsp`)
- 이슈 기록: law-url-double-prefix, notice-popup-post-navigation
- 지식 기록: knowledge/troubleshooting/spring-url-double-encoding

## [2026-05-20] session | dna-sql-agent-web — 대화 이름 변경 UX, Toast 패턴 통일, 설계 문서 정비

## [2026-05-20] session | dna-sql-agent-web — /ui 미리보기 페이지 추가 & PR #8 생성

## [2026-05-21] session | dna-sql-agent — 채팅 대화 제목 수정 API(PATCH) 및 단위 테스트 추가

## [2026-05-21] decision | dna-sql-agent-web — ADR-003 destructive 색상 토큰 구조 정의

## [2026-05-21] session | dna-sql-agent — 채팅 목록 상단 고정(pin) + 결과 카드 즐겨찾기(bookmark) 기능 구현

## [2026-05-21] session | dna-sql-agent-web — 북마크 기능 구현 (BookmarkView, flat prop, patchBackendMessageIds)

## [2026-05-22] session | dna-sql-agent — bookmark 설계 문서 정리 및 PR #25 생성

## [2026-05-26] session | dna-sql-agent-web — 북마크 UX 개선 & SSE done 이벤트 message_id 수신 처리

## [2026-05-26] decision | dna-sql-agent-web — ADR-004 SSE done 이벤트에서 message_id 직접 수신

## [2026-05-26] session | dna-sql-agent — 북마크 message_id SSE 전달 & 차트 E2004 수정 (PR #27)

## [2026-05-26] decision | dna-sql-agent — ADR-003 SSE done 이벤트에 message_id 포함

## [2026-05-26] session | dna-sql-agent — 채팅 목록 API last_message 필드 추가 (PR #28)

## [2026-05-26] session | dna-sql-agent-web — 대화 목록 description · 북마크 soft remove 버그 수정 · HTTPS 배포

## [2026-05-26] fix | dna-sql-agent-web — 북마크 soft remove 재북마크 순서 유지 & useMemo filter 버그 수정

## [2026-05-27] session | dna-sql-agent-web — 시스템 권한 매트릭스 UX 재설계 (옵티미스틱, 인라인 row, 반응형)

## [2026-05-27] session | dna-sql-agent — refresh token 프론트엔드 연동 검토·테스트 및 PR #33 생성

## [2026-05-28] session | dna-sql-agent-web — refresh token 자동 갱신 & 가상 스크롤 도입

## [2026-05-28] decision | dna-sql-agent-web — ADR-007 401 인터셉터 큐 패턴 (refresh token rotation)

## [2026-05-28] session | dna-sql-agent-web — PR #22/#23/#19 머지 & AppHeader 공통 컴포넌트 추출

## [2026-05-28] decision | dna-sql-agent-web — ADR-008 AppHeader 공통 컴포넌트 (icon?, children, actions?)

## [2026-05-28] session | dna-sql-agent — PR #35 리뷰 및 머지 (slide_config 분리, 충돌 감지 레이아웃)

## [2026-05-28] session | dna-sql-agent-web — 보안 패키지 업데이트 & SessionExpiredError 타입 도입

## [2026-05-28] decision | dna-sql-agent-web — ADR-009 SessionExpiredError typed class (세션 만료 콘솔 에러 제거)

## [2026-05-29] session | dna-sql-agent-web — 사용자 그룹 수정 복구 및 그룹 관리 UI 전면 개선 (PR #30)


## [2026-05-29] session | dna-sql-agent-web — 관리자 개선: 권한 일괄 부여/해제 + 401 버그픽스 + UI 정렬

## [2026-05-29] issue | dna-sql-agent-web — refresh expires_in 누락 시 expiresAt null 저장 → 연속 401

## [2026-05-29] knowledge | troubleshooting — JSON.stringify NaN → null 직렬화 주의

## [2026-05-29] session | dna-sql-agent — 시스템 권한 일괄 부여/회수 API 추가 및 인증 개선 (expires_in, CORS 정리)

## [2026-05-29] decision | dna-sql-agent — ADR-005 bulk system permission API 설계 (INSERT...SELECT 패턴, code 필드 에러 응답)

## [2026-06-01] session | dna-sql-agent — sql_examples type 컬럼 반영 및 PR #38 생성

## [2026-06-01] session | dna-sql-agent-web — SQL 에디터 CodeMirror 교체, 포맷팅 버튼, 상태 태그 통일 (PR #32)
## [2026-06-01] decision | dna-sql-agent-web — ADR-010 SQL 에디터 CodeMirror 전환 (auto-resize, dangerouslySetInnerHTML 제거)
## [2026-06-01] knowledge | troubleshooting — overflow-y-auto 설정 시 자식 input focus ring 좌측 클리핑

## [2026-06-02] session | dna-sql-agent — ECharts 차트 엔진 추가 및 동적 스키마 구현 (PR #39)

## [2026-06-02] decision | dna-sql-agent — ADR-006 ECharts 엔진 설계 (table 처리, 동적 스키마)

## [2026-06-02] session | dna-sql-agent-web — ECharts 프론트엔드 구현 (PR #33) 및 SaveBanner 스크롤 인디케이터

## [2026-06-02] decision | dna-sql-agent-web — ADR-011 ECharts 프론트엔드 레이아웃 전략

## [2026-06-02] session | dna-sql-agent-web — 색상 시스템 리뉴얼 (뉴트럴 그레이 + 오렌지) + UI 컴포넌트 정비

## [2026-06-02] decision | dna-sql-agent-web — ADR-012 색상 시스템 뉴트럴 그레이 + 오렌지 포인트로 교체

## [2026-06-04] session | dna-sql-agent-web — 파비콘 재설계 및 다크모드 버튼/토글/라디오 UI 스타일 개선

## [2026-06-05] session | dna-sql-agent — ECharts scatter/bubble 개선 및 프론트·백 레이아웃 책임 분리

## [2026-06-05] decision | dna-sql-agent — ADR-007 ECharts 레이아웃 프론트엔드 전담

## [2026-06-05] issue | dna-sql-agent — Sankey DAG 사이클 오류 해결 (iterative DFS)

## [2026-06-05] knowledge | tools — ECharts tooltip JSON 환경 포맷터 패턴

## [2026-06-05] session | dna-sql-agent-web — ECharts 렌더링 개선 (Sankey 높이/scale, grid 기본값, 코드 정리)

## [2026-06-08] session | dna-sql-agent-web — 차트 팔렛트 통합 및 Sankey/채팅 UX 개선

## [2026-06-08] decision | dna-sql-agent-web — ADR-013 차트 공통 컬러 팔렛트 정적 상수 파일로 관리

## [2026-06-08] session | dna-sql-agent — ECharts combo/scatter label 추가, Sankey 버그 수정, 시스템 프롬프트 개선

## [2026-06-08] decision | dna-sql-agent — ADR-008 Sankey 컬럼 순서 기반 흐름 방향 아키텍처

## [2026-06-08] issue | dna-sql-agent — Sankey Oracle Decimal 티어 컬럼 오감지 (coerce_numeric)

## [2026-06-09] session | dna-sql-agent — asyncio 블로킹 해소 + 스트리밍 중단 시 사용자 메시지 저장

## [2026-06-09] decision | dna-sql-agent — ADR-009 동기 블로킹 호출에 asyncio.to_thread() 사용

## [2026-06-09] pattern | knowledge — SSE 스트리밍 중단 시 사용자 메시지 저장 패턴 (try/finally + stream_completed)

## [2026-06-09] issue | dna-sql-agent-web — 스트리밍 중단 메시지 차트 북마크 버튼 활성화 (isAborted 플래그로 해결)

## [2026-06-09] issue | dna-sql-agent-web — 새 대화 제목 변경·삭제·핀 시 로컬 UUID로 API 호출 → 404 (backendConversationId 사용으로 해결)

## [2026-06-09] issue | dna-sql-agent-web — 대화 메시지 로드 일시 실패 시 대화 목록 삭제 (404만 삭제하도록 수정)

## [2026-06-09] knowledge | troubleshooting — 프론트엔드 로컬 ID vs 백엔드 ID 불일치 패턴 문서화

## [2026-06-10] session | dna-sql-agent — SQL Guard DB 기반 전환 + 그룹×시스템 테이블 접근 제어 + LLM 재시도 방지

## [2026-06-10] decision | dna-sql-agent — ADR-010: SQL Guard schema.table 차단 지원

## [2026-06-10] decision | dna-sql-agent — ADR-011: 가드레일 차단 시 LLM 재시도 방지 전략

## [2026-06-10] session | dna-sql-agent — 마스킹 그룹 권한 DB 기반 전환

## [2026-06-10] decision | dna-sql-agent — ADR-012: 마스킹 그룹 액션 DB 이관 + 초기값 없음

## [2026-06-12] session | dna-sql-agent — 관리자 페이지 PR #50/#42 생성, 보고서 브랜치 환경 수정

## [2026-06-15] session | dna-sql-agent — 북마크 기반 대시보드 기능 백엔드+프론트엔드 전체 구현

## [2026-06-15] decision | dna-sql-agent — ADR-015: 북마크 SQL 추출 시점 + 캐시 전략

## [2026-06-15] issue | dna-sql-agent-web — widget-add-panel 클릭 불동 (ScrollArea 제거, z-10, div onClick으로 해결)

## [2026-06-15] session | dna-sql-agent — 대시보드 위젯 크기 모델 (프리셋·반응형 컬럼·비례 높이·푸터 대화 링크)

## [2026-06-15] decision | dna-sql-agent — ADR-016: 대시보드 위젯 크기 모델 (고정 프리셋 + 반응형 컬럼 + 비례 높이)

## [2026-06-15] knowledge | troubleshooting — 고정 높이 셀 안 차트 짤림 (border-box 카드 테두리까지 크롬 차감)

## [2026-06-16] session | dna-sql-agent — 로그아웃 후 이전 계정 대화 목록 표시 버그 수정 (useAuth 이중 인스턴스 → 단일 주입)

## [2026-06-17] session | dna-sql-agent — PPT 애드인 HTTP 28001 지원 & Docker 네트워크 구조 탐색/롤백

## [2026-06-17] decision | dna-sql-agent-web — ADR-015 nginx HTTP 28001 포트로 PPT 애드인 지원

## [2026-06-17] issue | dna-sql-agent — Docker 커스텀 네트워크 컨테이너 간 통신 불가 (iptables FORWARD DROP → --network host 롤백)

## [2026-06-17] knowledge | troubleshooting — Docker 커스텀 네트워크 iptables FORWARD DROP 문제 및 --network host 대안

## [2026-06-17] knowledge | troubleshooting — Docker --publish 127.0.0.1:port:port 로 외부 직접 접근 차단

## [2026-06-17] session | dna-sql-agent — 대시보드 UI 개선 (위젯 제거/스크롤 그림자/system_display_name 백엔드 통합), git filter-branch 히스토리 수정

## [2026-06-23] session | dna-sql-agent — run_sql LIMIT 자동 주입 고지 및 DataTable 정렬·sticky 헤더

## [2026-06-23] issue | dna-sql-agent — 북마크 query_sql에 LIMIT 미반영 (tool_calls는 도구 실행 전 저장 → create_bookmark에서 _inject_limit)

## [2026-06-23] knowledge | troubleshooting — shadcn/ui Table sticky 헤더가 overflow 래퍼 때문에 고정 안 됨 (plain table 교체)

## [2026-06-25] session | dna-sql-agent — 시스템 제외 테이블·테이블 접근 제어 목록 선택 UI (#68), DB 연결 버전, 설정 화면 정리

## [2026-06-25] decision | dna-sql-agent — ADR-017 LLM 연결 관리는 즉시 저장으로 통일 (dirty-save 폐기)

## [2026-06-25] issue | dna-sql-agent — 설정 리셋이 저장값 복원 안 됨 (ctx.reset 공장초기화 + 권한 카드 resetRef 미배선)

## [2026-06-25] knowledge | patterns — 요청 토큰(reqRef)으로 stale 비동기 응답 무시 (다이얼로그/탭 전환 race 방지)

## [2026-06-26] session | dna-sql-agent — GeoJSON 지도 시각화 (점·지명 색칠·흐름) + 대시보드 개선

## [2026-06-30] session | dna-sql-agent — 북마크 표시 누락 수정 + 지도(flow/point) 시각화·데이터 목록 개선

## [2026-06-30] issue | dna-sql-agent — flow map 범례 누락 (color==from_label일 때 display_cols 제외 회귀)

## [2026-06-30] issue | dna-sql-agent — 채팅 북마크 표시 누락 (진입 시 미로드 + 페이지네이션) → 대화별 refs 조회

## [2026-06-30] decision | dna-sql-agent — ADR-019 지도 목록을 from==to 기준 분류·from/id 그룹핑

## [2026-06-30] knowledge | troubleshooting — pandas df.to_json()이 datetime을 epoch 밀리초(숫자)로 직렬화 (date_format="iso")

## [2026-07-03] session | dna-sql-agent — 사이드바/헤더 구조 개편(대시보드 사이드바 승격), 대시보드 안정화, 서비스 매뉴얼 백엔드 연동

## [2026-07-03] decision | dna-sql-agent — ADR-020 라우트에 따라 사이드바 컴포넌트 자체를 교체(숨김 대신 스왑)

## [2026-07-03] issue | dna-sql-agent — 로그아웃 후 재로그인 시 대시보드/북마크 상태 잔존 → 재로드 안 됨(2단계 버그)

## [2026-07-03] issue | dna-sql-agent — 대시보드 전환 시 화면 깜빡임 + 스크롤 불가(리마운트 + h-full 체인 끊김)

## [2026-07-03] knowledge | troubleshooting — overflow-y-auto가 안 먹힘 — 스크롤이 아니라 조상 h-full 누락으로 클리핑되는 것

## [2026-07-06] session | dna-sql-agent — 관리자 페이징·다이얼로그 정리, 대화 제목 버그, 시스템 목록 성능 개선

## [2026-07-06] decision | dna-sql-agent — ADR-021: 관리자 목록 서버사이드 페이징 (페이징 API + 무페이징 roster API 병행)

## [2026-07-06] issue | dna-sql-agent — 새 대화 제목 빈 문자열 센티널이 기본값 변경으로 깨짐 (첫 메시지 자동 갱신 불가)

## [2026-07-06] issue | dna-sql-agent — 시스템 목록 API 응답 지연 — N+1 쿼리 + table_relation_info 대용량 JSON 컬럼 전체 조회

## [2026-07-06] knowledge | troubleshooting — React 컨트롤드 number input, 같은 숫자값이면 DOM 미갱신 (ref로 직접 커밋 필요)

## [2026-07-09] session | dna-sql-agent — 채팅 북마크 이동, 지도 선택 중복 수정, 대시보드 고정 날짜·드래그 성능

## [2026-07-09] decision | dna-sql-agent — ADR-022: 상대 날짜는 DB 동적 함수로 생성 + 대시보드 고정 날짜 감지·경고 병행

## [2026-07-09] issue | dna-sql-agent — 지도 point 좌표+속성 완전 동일 행에서 다중 선택 (Feature.id 부재)

## [2026-07-09] issue | dna-sql-agent — 북마크 삭제해도 열려있는 대시보드 위젯 안 사라짐 (activeId 불변 가드로 재조회 누락)

## [2026-07-09] issue | dna-sql-agent — 대시보드 드래그·드롭 시 무거운 위젯(지도) 버벅임 (리렌더 + GPU 레이어 미승격 + props 참조 불안정)

## [2026-07-09] knowledge | patterns — 드래그앤드롭 그리드 무거운 자식 리렌더 최적화 체크리스트 (React.memo + will-change + props 참조 안정성)

## [2026-07-15] session | kacportal — 스마트기기 이용통계 엑셀 다운로드 sheetName 버그 수정 + 로컬 Tomcat 디버그 환경 구축

## [2026-07-15] issue | kacportal — 엑셀 다운로드 버튼 무반응 — xl.sheetName 누락으로 makeXl() TypeError

## [2026-07-15] issue | kacportal — 로컬 Tomcat(cargo-maven3-plugin) 실행 전면 실패 — pom.xml 문법 오류 + war 패키징 누락 + Altibase 드라이버 비활성화 3단 연쇄

## [2026-07-15] knowledge | troubleshooting — cargo-maven3-plugin "Cannot find 'property' in class Configuration" — <property> 단수 문법 대신 <properties> Map 바인딩 필요

## [2026-07-15] knowledge | patterns — 정적 HTML 하니스로 DB/백엔드 없이 프론트 로직만 실제 라이브러리로 검증하기

## [2026-07-16] session | dna-sql-agent — 그룹 관리자(Group Admin) 기능 정책 설계 + 백엔드 구현

## [2026-07-16] decision | dna-sql-agent — ADR-023: 그룹 관리자 역할과 이중 레이어 권한 모델(그룹↔시스템 매핑 vs 사용자 권한)

## [2026-07-16] session | dna-sql-agent-web — 그룹 관리자(Group Admin) 기능 프론트엔드 구현

## [2026-07-16] issue | dna-sql-agent-web — 그룹 관리자 지정해도 관리자 페이지 진입 방법 없음 (역할 캐시 미재검증 + 진입 버튼 조건 누락)

## [2026-07-16] knowledge | patterns — 권한 라우트 진입 시 서버 재검증 — 로그인 시점 캐시만 믿지 않기

## [2026-07-22] session | dna-sql-agent — 그룹 관리자 기능 마무리(default_grant 시딩, 권한 매트릭스 스코프, 벌크 이동), PR #117 머지

## [2026-07-22] decision | dna-sql-agent — ADR-026: 그룹 관리자 정책 v0.9 refinements

## [2026-07-22] session | dna-sql-agent-web — 그룹 관리자 화면 마무리(그룹원 관리 다이얼로그 재설계), PR #72 머지

## [2026-07-22] knowledge | troubleshooting — PostgreSQL COLLATE "und-x-icu"로 한글/영문 혼용 정렬 문제 해결

## [2026-07-24] session | dna-sql-agent-web — SQL 카드 렌더링 성능 개선 + 채팅 목록 로딩 체감 지연 조사

## [2026-07-24] decision | dna-sql-agent-web — ADR-016: SQL 카드 하이라이팅, Prism+sql-formatter 이중 파싱 구조 유지

## [2026-07-24] knowledge | patterns — Prism 토큰을 dangerouslySetInnerHTML 없이 React 엘리먼트로 렌더링

## [2026-07-24] knowledge | troubleshooting — "느려 보인다" 진단은 API 시간보다 next dev/prod 여부부터 확인

## [2026-07-28] meeting | dna-sql-agent — 환경설정, 관리자기능, 권한, 라이선스 정책 검토

## [2026-07-28] session | dna-sql-agent — self-hosted 러너 디스크 풀 대응 + 이미지 빌드 컨텍스트 보안 강화

## [2026-07-28] decision | dna-sql-agent — ADR-028: 배포 이미지 빌드 컨텍스트 최소화 및 민감 파일 격리

## [2026-07-28] issue | dna-sql-agent — self-hosted 러너 디스크 풀, docker buildx 캐시 149.7GB 누적

## [2026-07-28] knowledge | troubleshooting — docker buildx 캐시 무제한 누적 → 디스크 풀

## [2026-07-28] knowledge | patterns — Docker 멀티스테이지 버려지는 컨텍스트 스테이지로 민감 파일 완전 제거

## [2026-07-29] decision | dna-sql-agent — ADR-028 후속: requirements.txt 격리(context 스테이지) 실제 적용은 보류, 리스크 대비 비용 안 맞음

## [2026-07-29] session | dna-sql-agent — Nuitka .pyi 유출 실제 수정 + 시크릿 관리 점검

## [2026-07-29] decision | dna-sql-agent — ADR-027 후속: --no-pyi-file로 .pyi 유출 차단

## [2026-07-29] issue | dna-sql-agent — JWT_SECRET_KEY 하드코딩 기본값 fallback (미해결)

## [2026-07-29] knowledge | patterns — Nuitka --no-pyi-file로 .pyi 스텁 유출 차단

## [2026-07-29] knowledge | troubleshooting — stale 로컬 브랜치 기준 git diff가 이미 머지된 커밋을 새 변경사항으로 보여줌

## [2026-07-31] session | dna-sql-agent — 대화 시스템 권한 우회 취약점 수정 (조회 대상 System 서버 확정)

## [2026-07-31] decision | dna-sql-agent — ADR-029: 클라이언트 metadata 폐기, 대화 레코드에서 스코프 확정 + 매 요청 권한 재확인

## [2026-07-31] issue | dna-sql-agent — 시스템 스코프 없으면 테이블 접근 제한이 사라짐 (fail-open, 정책 대기)

## [2026-07-31] issue | dna-sql-agent — 권한 회수 후에도 대화 이력의 이전 시스템 테이블명이 LLM 문맥에 남음 (정책 대기)

## [2026-07-31] issue | dna-sql-agent-web — /chat/[id] conversation_id 가 동작하지 않던 문제, 라우트 제거 후 세션 인증 시 재도입

## [2026-07-31] knowledge | patterns — 조회 대상(스코프)은 클라이언트 입력이 아니라 서버가 레코드에서 확정

## [2026-07-31] knowledge | troubleshooting — 로그가 안 찍힌 것을 근거로 쓰기 전에, 그 로그가 찍히는지부터 확인

## [2026-08-03] session | dna-sql-agent — 채팅 요청 경로의 중복 DB 조회 정리 (요청 단위 캐시)

## [2026-08-03] knowledge | patterns — ContextVar 요청 단위 캐시: 수명은 "요청"이 아니라 "태스크"

## [2026-08-04] session | dna-sql-agent — 고객사 배포 패키지 구축 (별도 저장소 · 이미지 전달 · 마운트 권한 처리)

## [2026-08-05] session | dna-sql-agent — 설정 출처 일원화(.env 직독) · 배포 패키지 워크플로 구축

## [2026-08-05] decision | dna-sql-agent — ADR-032 접속정보의 출처를 .env 하나로 고정

## [2026-08-06] session | dna-sql-agent — 임베딩 모델 폐쇄망 조사(이미지 번들링) · 배포 하드닝 1차 마무리 PR 2건

## [2026-08-06] knowledge | troubleshooting — GitHub Actions boolean 입력은 표현식에서 문자열이라 "false" 도 참

## [2026-08-06] knowledge | troubleshooting — 도커 빌드 컨텍스트는 클라이언트가 읽어 전송한다 (원격 데몬이어도 소스는 로컬 필요)

## [2026-08-06] meeting | dna-sql-agent — 다답 일정 및 사업 현황 정리 (LH PoC 서버 이슈 · 한전 9~10월 · 온톨로지 인메모리 · AI FESTA 8/18 마감)

## [2026-08-07] lint | dna-sql-agent — 114페이지 점검: type 어휘 오탈자 5건 통일, 깨진 링크 5건 해소(이슈 3·knowledge 1 신규 작성, ADR 파일명 오타 1), overview/architecture 낡은 내용 갱신(Plotly→다중 엔진, ADR 표 001~004→주요 발췌), status.md 단계 표기 "초기 설정"→"배포·납품 준비", index.md 누락 knowledge 11건 등재, 프론트매터 규약을 실태(type/project/date)에 맞게 재작성

## [2026-08-10] session | dna-sql-agent — 라이선스 위조 위협모델 분석(HMAC 대칭키 한계·Ed25519 권고) + 서버 부트스트랩 로직 dna/app 분리해 Nuitka 난독화(PR #138). config 단일 검증 소스로 인한 키파일 갱신 footgun 규명.

## [2026-08-12] session | kacportal — 기사 수집 건수 차트 x축 기간순 정렬 수정(labelISO 기준 정렬 + categories 고정, dev 47af1dea2). "DevExtreme가 문자열 라벨을 자체 정렬한다"는 초기 진단은 실측으로 오진 판명 — 근본 원인(상용 Tibero 반환 순서)은 미확인. 로컬 실행환경을 저장소 밖 러너로 재구축(.vscode/launch.json 단독 실행+디버그). 법령검색 multi_match 기본값 문제 1차 분석.

## [2026-08-12] issue | kacportal — 기사 수집 건수 차트 x축 순서 뒤섞임: 클라이언트 렌더링·자바 경로·매퍼 분기 배제, 화면단 방어만 적용(미해결)

## [2026-08-13] session | dna-sql-agent — defaults 를 설정 검증 스펙으로 겸용(기동 시 검증 + 스펙 린터, ADR-034) · 설정/RAG 문서 재편으로 사본 제거하고 정본 단일화

## [2026-08-13] issue | dna-sql-agent — 도구 권한 전부 해제가 전원 허용으로 뒤집히는 fail-open 규명. origin/main 의 pending_permission_seed 가 우리 구조에서는 목적을 잃는 이유와, 기준을 '행 없음 = 거부'로 통일하는 전환 순서 기록

## [2026-08-13] session | dna-sql-agent — 설정 API 관리자 전용화, 설정 정의를 API_SECTIONS 하나로 통합, origin/main(질의 명확화 26커밋) 병합. 서버 PR #140 · 웹 PR #82 생성, CLAUDE.md 에 PR 양식 기록

## [2026-08-14] session | dna-sql-agent — 도구 권한 fail-open 정리(빈 목록 = 거부, 판정 3벌 통합, 최초 설치 시딩 보강, ADR-035) · 설정 적용 시점을 ApplyMode 로 선언하고 미반영을 헤더에 알리는 배너 도입(ADR-036) · estimator 설정이 통째로 무시되던 버그 수정

## [2026-08-20] session | dna-sql-agent — 차트 다중 시리즈를 `y` 쉼표 목록으로 지원(세 엔진 공용 컬럼 해석기) · 엔진별 지원 타입 차이를 도구 스키마 조립에서 흡수(ADR-037) · 이중 축은 인자가 아닌 `combo` 타입으로 확정하고 plotly 에 구현(ADR-038) · 구현했으나 스키마에 없어 LLM 이 "지원 안 함"이라 답하던 문제 규명. 서버 PR #154 · 웹 PR #88

## [2026-08-25] issue | dna-sql-agent — 차트 다중 시리즈·combo 도입분(PR #154) 코드 리뷰 지적 5건 기록: plotly combo 라인 컬럼 폴백 중복으로 DuplicateError · ECharts sankey 만 resolve_column 누락 · `_preprocess_df` 가 쉼표 `y` 를 몰라 agg·sort_by 조용히 무실행 · `_validate_columns` 가 x·color 까지 쉼표 분리해 LLM 자기수정 단서 소실 · ECharts combo 중복 시리즈. 전부 미검증·미수정

## [2026-08-25] session | dna-sql-agent — 폐쇄망 미지원 항목 전수조사 후 지도 배경 타일을 런타임 env 로 전환(ADR-039, 웹 PR #89): `/map-config` 라우트가 요청 시점 env 를 읽어 내려주고 지정한 모드만 화면 토글에 노출. 배포 패키지에 `.env` 배선·설치 문서 추가. 배포 패키지를 맥에서 기동해 arm64 도커 빌드 실패(x64 네이티브 하드코딩)·이미지 10GB(models/ 미제외 + CUDA torch)·라이선스 머신 바인딩(Linux 는 hostname 미검사) 3건 규명

## [2026-08-26] session | dna-sql-agent-deploy — 고객사에서만 임베딩 모델을 못 찾는 문제 원인 규명(미해결). 패키지 zip·`--with-models` 반입 방식·마운트는 `zipinfo`/`docker inspect` 로 모두 정상 확인, 후속 DNS 오류(`Errno -3`)와 `HF_HUB_OFFLINE` 미설정은 원인이 아님을 배제. `os.path.isfile()` 이 권한 부족을 `False` 로 뭉개 "없음" 과 "못 읽음" 이 같은 로그가 되는 구조 규명. `docker-entrypoint.sh` 의 chown 목록에 `models` 가 없고 `:ro` 라 넣어도 안 되는 사각지대 확인. 개발 서버 `chmod o-rx` 재현 시험은 소유자 UID 가 마침 1005 라 무효였음

## [2026-08-26] issue | dna-sql-agent-deploy — 마운트·파일 다 정상인데 임베딩 모델 미탐지: 앱 UID(1005) 접근 권한 부족이 유력, 후보 3개로 좁힘(권한 / `embedding.json` 모델명 불일치 / 압축 미해제). 고객사 `exec -u 1005` 출력 대기, 미해결

## [2026-08-26] lint | dna-sql-agent-deploy — 7페이지 점검: 깨진 링크 5건 해소(프로젝트 폴더명 직접 링크 → `[[projects/X/overview|X]]` 관행으로, overview 4·ADR-001 1), 누락된 `sessions/000-template.md`·`issues/000-template.md` 생성(`/wiki-end` 가 참조하는 대상인데 이 프로젝트만 없었음), status.md 의 완료된 TODO 이동(`package.yml` 이름은 이미 `Build Installation Package (Mobigen)` 로 정리됨 / Qdrant 1.17.0↔v1.12.4 불일치는 유효 확인), index.md 에 deploy ADR-001 등재 + `### 패턴` 중복 헤더를 실제 내용에 맞게 `### 주요 결정 (ADR)` 로 정정, overview.md 갱신(updated 날짜·hf_cache 설명 정정·이슈/세션 링크 추가). 프론트매터 7건 전부 규약 준수, `resolved: false` 1건은 실제 미해결 확인

## [2026-08-26] lint | dna-sql-agent — 149페이지 점검: 프론트매터 규약 위반 0건(raw/ 4건은 LLM 편집 금지 폴더라 제외), 깨진 링크 1건 수정(overview.md 표 밖에서 `\|` 를 써 ADR-006 링크가 안 열리던 문제 — 표 안의 `\|` 9건은 정상). `resolved: false` 9건 전부 코드로 대조해 실제 미해결 확인(차트 리뷰 5건은 `line_cols` 폴백·`_preprocess_df` 의 `args.y in df.columns`·`_validate_columns` 전 필드 쉼표 분리가 그대로, sql-guard fail-open 도 그대로). **JWT 이슈는 상태가 악화된 채 기록만 옛 형태였음** — 2026-08-19 `df1998c` 가 `os.getenv("JWT_SECRET_KEY", ...)` 를 지워 이제 서명키가 재정의 불가능한 하드코딩이 됨. 이슈 페이지를 현행으로 재작성하고 계기(미사용 환경변수로 오인)를 기록. index.md 갱신(dna-sql-agent 행 2026-08-13→2026-08-25·stack 에 nuitka, ADR-039 등재 누락 보완, JWT 이슈 설명 정정), overview.md 갱신(updated 2026-08-18→2026-08-26, ADR 건수 32→39). 남은 권고: status.md 72KB 비대·knowledge/tools/ 에 nuitka·qdrant 페이지 부재


## [2026-08-28] session | dna-sql-agent-deploy — 고객사 폐쇄망 설치 완주. 2026-08-26 부터 미해결이던 임베딩 모델 미탐지 **원인 확정**: 모델 파일이 `700` 으로 반입됐고 `models` 만 `:ro` 마운트라 엔트리포인트 chown 자가치유에서 빠져, 비-root 앱 계정이 진입조차 못 했다(`isfile()` 이 이를 `False` 로 뭉갬). 컨테이너 경유 `chmod -R go+rX` 로 해소. 고객사 서버가 **rootless Docker + vfs** 임을 규명 — UID `101004` 은 subuid 매핑이었고(컨테이너 0 → 호스트 사용자, 1+ → 100000번대), 그래서 `--user $(id -u)` 가 아니라 **`--user 0:0`** 이 맞다. vfs 때문에 4GB 적재에 수 시간·컨테이너 생성마다 이미지 전체 재복사. `fuse-overlayfs` 가 이미 설치돼 있으나 담당자가 "일단 유지" 결정. 부수로 `dnasql_agent` DB 미생성(postgres `initdb` 는 빈 폴더에서만 동작) 해소

## [2026-08-28] issue | dna-sql-agent-deploy — 임베딩 모델 미탐지 **해결 완료**로 갱신(`resolved: true`). 근본 원인은 패키지 만드는 쪽 umask 가 `hf download` → `cp -R` → `zip`(유닉스 퍼미션 저장) → 고객사 압축 해제까지 그대로 살아남는 것. 정본 수정은 `package.sh` 에 `chmod -R a+rX "$MODEL_STAGE"` (미구현), `init.sh` 보정은 보조 수단으로만

## [2026-08-28] issue | dna-sql-agent-web — 폐쇄망에서 관리자·대시보드 버튼 미표시(미해결). `sidebar-user-menu.tsx:38` 이 `isOfficeAddin === false` 로 게이팅하는데 `use-office-addin.ts` 가 `load` 만 듣고 `error` 를 안 들어, 외부 office.js(`app/layout.tsx:65`, Microsoft CDN)가 실패하는 폐쇄망에서 판정이 `null` 로 남는다. 로그인·DB·`isAdmin` 은 전부 정상이라 원인이 드러나지 않는다. 우회는 `/admin` 직접 접근(`app/admin/layout.tsx` 는 `isOfficeAddin` 미참조)

## [2026-09-03] issue | dna-sql-agent — 관계정보 생성이 400 으로 실패: `max_tokens=65536` 폴백 경고와 `exceed_context_size_error` 가 한 요청의 연쇄임을 규명. 배포된 LLM 서버의 가용 컨텍스트(2816토큰)가 프롬프트(4873토큰)보다 작은 것이 근본 원인이고 `max_tokens` 하드코딩은 1차 400 의 원인일 뿐. 서버 `--max-model-len`/`-c` 상향이 정본이며 청크 12→4~6·`max_tokens` 설정화는 완화책. 로그 URL 이 `/v1` 아닌 `/1` 로 찍히는 건도 함께 기록(미해결). 일반화: [[knowledge/troubleshooting/openai-compatible-server-context-window-400]]

## [2026-09-03] issue | dna-sql-agent — "처음 배포 시 `ValidatedRunSqlTool` 권한 없음" 재점검. 2026-08-14 `cabfe86` 로 최초 설치는 해결됐으나 두 구멍이 남음: 최초 설치 판정이 `config/tool_access.json` 파일 존재라 영속 볼륨 업그레이드 배포에서는 영영 시딩 안 됨 · 그룹이 빈 순간에 시딩이 돌면 부여 실패인데도 표식만 소진됨. 부트스트랩 그룹(`admin`·`user`)이 `schema.py` 의 직접 INSERT 라 신규 그룹 경로를 안 타는 비대칭도 확인. 기존 이슈 페이지에 추가 절 삽입, 일반화: [[knowledge/troubleshooting/first-install-detection-by-file-presence]]

## [2026-09-03] issue | dna-sql-agent — 기능 설명의 "등록된 예시를 few-shot 참조" 가 구현과 불일치: `_format_prompt_context()` 가 설명·SQL 만 싣고 등록된 질의문은 벡터 검색 키로만 쓰여 LLM 에 안 보임. 더해 `search_limit` 기본값이 1(one-shot)이고, 벡터화 잡이 돈 `status='active'` 예시만 검색 대상. 구현 수정(질문 한 줄 추가) 또는 문구 수정 중 택일 미결정


## [2026-09-16] session | dna-sql-agent — 지도 배경 `API KEY REQUIRED` 워터마크의 원인이 **CARTO 의 무료 베이스맵 정책 변경**임을 규명. 환경변수 추가가 원인이라는 최초 가설은 기각(설정이 어디에도 없었음). HTTP 200 에 워터마크가 **타일 그림 안**에 인쇄돼 오는 형태라 로그·상태 코드로는 안 잡히고, 타일을 받아 열어보고서야 드러났다. 대안 3종을 실측 비교해(CARTO 키 발급 / OpenFreeMap 벡터 / Esri 래스터) **키·계정이 필요 없는 Esri 회색 캔버스**로 기본값 교체 — 납품 제품이라 기본값이 특정 업체 계정에 묶이면 안 되고, 벡터는 maplibre(gzip 293KB)+WebGL 의존과 지도 다중 표시 시 컨텍스트 상한이 걸린다. 지명이 별도 레이어인 특성에 맞춰 라벨 타일을 z-index 250 pane 에 추가하고, 한국 커버리지(밝은 z13·어두운 z16)를 `maxNativeZoom` 으로 흡수. PR 웹 #90. → [[projects/dna-sql-agent/decisions/040-keyless-raster-basemap]], [[knowledge/tools/keyless-map-tile-providers]]

## [2026-09-22] session | dna-sql-agent — 슬래시 커맨드를 DB 등록형으로 재구성하고 입력창 목록을 추가(PR 백엔드 #162·웹 #93). 커맨드 정의는 `slash_commands` 테이블에, 실행 로직만 코드에 두고 builtin·text·skill 세 방식과 public·admin 범위로 정리. 모든 커맨드 턴을 이력에 저장하되 LLM 맥락에는 스킬만 넣고, 스킬은 원문 저장 + 지시문 스냅샷을 LLM 직전에 블록으로 펼침(필터는 목록 마지막 — 대화 요약의 턴 번호 보존). 커맨드 결과는 카드·마크다운 링크 대신 전용 `item_list` 컴포넌트로 보내 새로고침 순서 문제를 구조적으로 제거. 곁가지로 LLM이 프롬프트 템플릿의 예시·자리표시자를 베끼는 패턴을 정리. → [[projects/dna-sql-agent/decisions/041-slash-commands-db-registry]], [[projects/dna-sql-agent/decisions/042-skill-turn-snapshot-and-llm-expansion]], [[projects/dna-sql-agent/decisions/043-command-result-dedicated-component]], [[knowledge/prompting/llm-copies-template-placeholders]]


## [2026-09-22] session | dna-sql-agent — 차트 북마크 404와 북마크 해제 UX 정리(PR 백엔드 #163·웹 #94). 북마크 404는 컴포넌트를 도구 호출 행마다 나눠 저장(8월 중순부터)하는데 웹이 여러 행을 한 답변으로 합치며 첫 행 id만 보내서 발생 — 서버가 컴포넌트 id로 실제 행을 찾아 보정하고, 웹은 단계마다 저장 행 id를 유지. 북마크 페이지 해제는 즉시 삭제·재생성이라 고정·순서가 바뀌고 대시보드 위젯이 CASCADE로 영구 삭제되던 문제를, 저장 전까지 보류 + 상단 저장·되돌리기 + 이동 가드로 해결하고 대시보드 삭제 안내 추가. 앞서 SQL 예제 AI 생성 실패(task 러너 작업 테이블 불일치)를 고치고, 0건 원인이 대상 DB의 `pg_stat_statements` 미설정임을 규명. → [[projects/dna-sql-agent/decisions/044-bookmark-page-deferred-remove]], [[projects/dna-sql-agent/issues/bookmark-component-row-mismatch-404]], [[knowledge/patterns/defer-destructive-toggle-until-save]], [[knowledge/troubleshooting/merged-rows-single-id-loses-child-location]], [[knowledge/troubleshooting/sql-history-collection-prerequisites]]

## [2026-10-01] session | dna-sql-agent-web — 개인 데이터셋 관리 화면 정리와 관리자 설정 저장·적용 흐름 복원(PR 백엔드 #170 머지·#172, 웹 #97, 설정 브랜치 2개 push 전). 데이터셋 다이얼로그 톤앤매너·단계 칩·구축 중 삭제 차단, PR #96 이 밀어낸 헤더 북마크 위치 복구. 지식화 단계가 이전 실행 상태를 보여주던 원인은 상태를 시스템 단위로만 저장하는 구조(최근 job·메모리 취소 플래그) — 이번 실행 job 만 응답, relation_info 사전 생성, 진입점 통일로 막고 실행 ID 는 후속. 관계 FAQ SQLite 스레드 오류는 check_same_thread + progress handler 타임아웃. 관리자 화면 개인 데이터셋은 이름 prefix 가 BIRD 공용 연결과 겹쳐 `owner_user_id` 로 구분. 관리자 설정이 저장만 해도 적용되던 건 멀티 워커 전파 신호를 저장 시점에 쓴 탓 — 신호는 적용 시에만, 표식은 공유 파일, 프롬프트 캐시 신호 분리. 배너는 전체 탭 기준 4버튼 + ※ 반영 방식 안내. PR #160 머지에서 유실된 목록 검색·정렬 복구. 운영은 단일 프로세스임을 배포 설정으로 확인해 재시작 시 고아 job 자동 정리는 보류. → [[projects/dna-sql-agent/decisions/045-connections-owner-user-id-personal-dataset]], [[projects/dna-sql-agent/decisions/046-settings-reload-signal-on-apply-only]], [[projects/dna-sql-agent-web/decisions/017-settings-banner-global-save-and-apply-hint]], [[knowledge/troubleshooting/sqlite-connection-shared-across-asyncio-threads]], [[knowledge/patterns/cross-worker-settings-signal-on-apply]], [[knowledge/troubleshooting/merge-keep-ours-silently-reverts-other-features]]

## [2026-10-01] meeting | dna-sql-agent — AI FESTA 26 준비 페이지 생성 (10/6~8 코엑스 C홀, 행사 개요·전시 구성·부대 프로그램 서칭 정리, 설명 포인트(관계도·스키마/밸류 프로파일링·관계형 FAQ·SQL Example·검색 흐름)와 부스 예상 Q&A 16개 추가) → [[projects/dna-sql-agent/meetings/2026-10-01 AI FESTA 준비]]
