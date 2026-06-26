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
