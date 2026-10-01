---
type: troubleshooting
project: dna-sql-agent
date: 2026-10-01
resolved: true
root-cause: "멀티 워커 전파 신호를 저장 시점에 쓰고, 따라잡기 조건에 자기 미적용 표식 포함"
related: [settings, hot-reload]
tags: [multi-worker, settings]
---

# 관리자 설정이 저장만 해도 자동 적용됨

## 증상

설정 적용 대상(RAG·에이전트·감사 로그·도구 접근·그룹 권한)을 저장하면 "적용 필요" 배너가 뜨지 않고 바로 반영됨. 단일 프로세스 운영에서도 동일.

## 근본 원인

9/08 커밋 f41fc995(큰 기능 커밋에 섞여 들어옴)의 멀티 워커 따라잡기:
- 저장 API(`mark_db_changed`)가 리로드 스탬프를 씀
- `_is_catchup_due()` 가 "자기 워커 미적용 표식"·"미적용 파일 설정"만으로도 참
- 저장 직후 화면이 부르는 `GET /pending` 요청 앞단 미들웨어가 적용을 실행하고, 그 뒤 계산된 미적용 목록은 비어 있음

## 해결 방법

ADR [[projects/dna-sql-agent/decisions/046-settings-reload-signal-on-apply-only]] — 스탬프는 적용 시에만, 표식은 공유 파일, 프롬프트 캐시 신호 분리. 브랜치 `fix/settings-apply-timing`.
