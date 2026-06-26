---
type: project-status
project: project-nova
updated: 2026-06-12
phase: active
---

# project NOVA — 현재 상태

## 개요

사내 AI 업무 활용 skill 공모전

## 완료된 것

- [x] 아이디어 기획안 작성 (Mail2Issue)
- [x] 전채린 제안 주제 '메일 기반 프로젝트 별 이슈 관리'로 5명 공동 출전 확정
- [x] 접수양식 담당 부분 초안 작성 (해결 방식 파트)
- [x] 2026-05-20(수) 오전 회의 — 접수 문서 최종안 작성
- [x] 2026-05-22(금) 접수 문서 제출
- [x] 1차 합격 — 2026-06-01 착수 회의 진행
- [x] Gmail 연동 알아보기 — 메일 내용·파일 목록 조회 가능, 파일 자체 다운로드는 기본 커넥션으로 불가
- [x] 진행 부분 skill 초안 작성하기
- [x] 워크 플로우 변경 회의 — 앞단에서 성격 단위로 분류 후 상세 태스크 정의는 후반부에서 진행하는 방식으로 정의

## 진행 중

- [ ] Skill 고도화
- [ ] 파이프라인 재정의 — 워크 플로우 재정의

## 다음 할 일

## 블로커

_(없음)_

## 메모

- 미팅: [[projects/project-nova/meetings/2026-05-18 주제 선정]]
- 문서: [[projects/project-nova/workflow|현재 워크플로우]] (2026-06-22, 빠른 경로 prep/LLM/finish 3국면이 00~06을 어떻게 수행하는지 포함)
- **설계 결정:** [[projects/project-nova/decisions/003-fwd-두턴-보존-최신턴-기준|ADR-003 FWD 두 턴 보존 + 최신 턴 기준]] (2026-06-19, **구현 완료** — demo FWD가 회신·전달요청에서 top_comment를 버려 꼬이던 구조적 원인 해결. ingest/rules/pipeline/run_pipeline 4파일 수정·검증)
- 트러블슈팅: [[projects/project-nova/issues/fwd-sender-our-reply-misclassification|FWD 회신을 고객 요청으로 오인]] (2026-06-19, 성격 판정에 서명 우선 규칙 추가 — ADR-003이 데이터 레이어로 흡수 예정)
- 트러블슈팅: [[projects/project-nova/issues/batch-same-thread-new-our-reply-ordering|같은 배치 new+our_reply 스레드 채번 어긋남]] (2026-06-19, finish 채번 루프 new 우선 정렬 + 정규화 제목 스레드 자동 연결)
- 트러블슈팅: [[projects/project-nova/issues/batch-received-time-ordering|배치 채번이 파일명순으로 매겨짐]] (2026-06-19, prep이 mail_id 부여 전 수신 시각순 정렬)
