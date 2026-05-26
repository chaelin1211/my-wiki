---
type: project-status
project: dna-sql-agent
updated: 2026-05-26
phase: active
---

# dna-sql-agent — 현재 상태

## 현재 단계

🔧 **초기 설정** 단계

## 완료된 것

- [x] 위키 프로젝트 폴더 생성
- [x] 계정 별 채팅 히스토리 유지를 위한 API, DB 설계 및 개발
- [x] LLM Context 유지 정책 스터디 및 장기 대화 요약 기능 구현
- [x] 계정 별 채팅 히스토리 유지 및 Context 유지를 위한 요약 기능 문서화
- [x] UI 작업 요소들 리스트업 (시각화 툴 수정 - chart 종류 추가 및 종류 선택 llm에게 일임)
- [x] few-shot 활용 전략 확정 — 비즈니스 로직/도메인 지식 제공용 (document RAG 구축 대신)
- [x] UI 개선 목표 방향 확정 — 오류 없이 동작, 한글화 우선(i18n 미적용), 관리자 페이지 포함
- [x] 웹 서버 배포
- [x] 서비스 명 확정 — 다답
- [x] 요구사항 담당자 할당 관련 검토
- [x] 브랜치 생성 — main / mania (백업·배포용) 분리
- [x] 진행사항 관리 방식 확정 — 시트 내 관리 (완료 여부, 완료 일자, 완료율)
- [x] bug fix: 시스템 비활성화 시 404 오류 (get_system_by_conn_and_name status 필터 문제)
- [x] bug fix: 채팅 생성 시 쿼리 수정 (시스템 조회 시 커넥션 매핑 확인)
- [x] bug fix: inactive 커넥션 목록 표시 및 채팅 필터 처리
- [x] bug fix: 대화 저장 시 tool 미사용·텍스트만 오는 경우 저장 안 되는 버그 (web 필터링)
- [x] feat: PATCH /api/v1/chat/{conversation_id}/title 대화 제목 수정 API 추가
- [x] test: JWT auth, chat history 단위 테스트 추가 (9건)
- [x] feat: 채팅 목록 상단 고정(pin) 기능 — PATCH /api/v1/chat/{id}/pin
- [x] feat: 채팅 결과 카드 즐겨찾기(bookmark) 기능 — /api/v1/bookmarks CRUD
- [x] feat: BookmarkResponse에 component_created_at 추가, 생성일 정렬 기준 변경
- [x] feat: SSE 종료 이벤트 → `{"type":"done","message_id":...}` (북마크 신규 메시지 404 해결)
- [x] fix: DevExtreme 차트 E2004 — 컬럼명 대소문자 무시 매칭 + auto-select fallback
- [x] 연관관계 추론 방식 확정 — 벡터라이징 시점에 수행, 쿼리 생성 시 추론 결과 포함하여 전달
- [x] 대화 목록 description — 마지막 메시지 조회 후 표시하도록 수정
- [x] bookmark PR #25 머지
- [x] PR #27 리뷰 및 머지 (fix/chat-bookmark — message_id SSE 전달, E2004 수정)
- [x] 프론트엔드 SSE done 이벤트 수신 및 북마크 연동 (type:"done" → message_id 활용)
- [x] 채팅 목록 제목 정책 수립 및 반영 (현재는 첫번째 user message)
- [x] 화면 - 채팅 목록 채팅 제목 밑에 No message 확인 및 처리
- [x] 요구사항 정리 문서 작성 및 담당자 배정

## 진행 중

- [ ] SQL Guard: group 별 테이블 접근 제한 처리 (현재 json 고정 데이터 → DB 연동, 화면·로직 변경 필요)
- [ ] SQL Guard: 관리자 페이지 수정 기능 연동
- [ ] SQL Guard: RAG 테이블 추출 시 프롬프트에 테이블 제약 포함 (top 테이블 사전 필터링)

## 다음 할 일

- [ ] 벡터 검색 정확도 개선 — 예상 질문을 컬럼별 아닌 관계(relation) 기준으로 재생성
- [ ] 테이블 선정 근거 로그 표시 화면 추가 검토
- [ ] 자동 벡터화 수정 화면 필요 여부 결정 (Qdrant 직접 수정 vs 별도 화면)
- [ ] office.js 기반 PPT 추가기능 개발 방안 검토
- [ ] 네트워크 공유 기반 추가기능 배포 방식 확인
- [ ] 슬라이드 삽입 요청 처리 흐름 구체화 (tool 호출 → 화면 감지 → 삽입)
- [ ] 발표 일정 확정 — 우선순위 1순위 수정·테스트 완료 후 fix (2026-05-25 주간 예정)
- [ ] 벡터라이즈 시 모델 재로딩으로 인한 API Hang 수정
- [ ] SQL reverse engineering: admin example 등록 화면에 수집 UI 추가
- [ ] SQL reverse engineering: 백엔드 자동 수집 로직 추가
- [ ] admin example 화면 vectorize 버튼 제거
- [ ] admin 수정 즉시 반영 항목 검토 및 처리

## 블로커

_(없음)_

## 메모

- 미팅: [[meetings/2026-05-13 SQL Agent 검토 회의 (실장님 제작 버전)|2026-05-13 SQL Agent 검토 회의 (실장님 제작 버전)]]
- 미팅: [[projects/dna-sql-agent/meetings/2026-05-18 활용 방안 및 제품명 결정]]
- 미팅: [[projects/dna-sql-agent/meetings/2026-05-26 벡터 연관관계 추론 및 SQL 리버스 엔지니어링 검토]]
- PPT 추가기능 동작 흐름 (실장님 설명):
  1. LLM에게 비율 상의 PPT 컴포넌트·내용 생성 요청
  2. LLM이 JSON 형식으로 슬라이드 구조 반환
  3. 웹에서 PPT 사이즈 기준으로 정확한 위치 계산 후 렌더링
  4. 스타일 템플릿은 웹 소스에 지정된 템플릿 사용
