---
type: project-overview
project: project-nova
created: 2026-05-15
updated: 2026-05-18
status: active
stack: [사내 LLM, n8n, 사내 메일 시스템, GitLab API]
repo: ""
goal: "사내 AI 업무 활용 skill 공모전 참가 — Mail2Issue (클라이언트 메일 자동 이슈화)"
---

# project-nova

## 목표

> 클라이언트 메일·첨부파일의 요청사항을 AI가 분해해 Git 이슈로 등록·추적까지 자동화하는 Skill을 구현해 사내 공모전(Project NOVA)에 제출한다.

## 기술 스택

| 영역 | 기술 | 선택 근거 |
|------|------|----------|
| AI | 사내 LLM | 내부 메일 보안·데이터 주권 |
| 오케스트레이션 | n8n | 시각적 워크플로우, 빠른 구축 |
| 메일 연동 | 사내 메일 시스템 (IMAP 또는 API) | 다우오피스 연동 가능 여부 확인 필요 |
| Git 연동 | GitLab API / GitHub REST API | 이슈 자동 생성 |
| 첨부파일 파싱 | 별도 파싱 모듈 검토 중 | PDF·엑셀·PPT 지원 필요 |

## 주요 의사결정

- 구현 방식: 사내 LLM + n8n (보안 우선) → [[decisions/001-llm-선택]]
- 아이디어 전체 개요: [[idea]]

## 현재 상태

→ [[projects/project-nova/status|상세 상태]] 참조

## 관련 지식

_(관련 knowledge/ 페이지 링크)_
