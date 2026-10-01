---
type: troubleshooting
project: dna-sql-agent
date: 2026-10-01
resolved: true
root-cause: "메모리 관계 정보 취소 플래그를 전체 재구축 경로만 초기화"
related: [personal-dataset, vectorization]
tags: [cancel, run-independence]
---

# 취소 후 파일 업로드로 다시 구축하면 관계 정보가 시작도 못 하고 실패

## 증상

```
RelationInfoCancelledError: Relation-info generation cancelled
```
새 실행의 `relation_info` job 이 `started_at` 없이 failed. 이어서 관계 FAQ 는 **이전 실행의 관계 그룹**으로 생성되어 완료로 표시.

## 재현 조건

관계 FAQ 진행 중 X(취소) → 파일 업로드로 다시 구축.

## 근본 원인

- X 는 (연결, 시스템) 단위 메모리 플래그를 켬. 플래그는 관계 정보 생성이 실행돼야 마지막에 지워짐
- 이미 관계 정보가 끝난 뒤 취소하면 플래그가 남음
- 전체 재구축 엔드포인트만 플래그를 초기화하고, 업로드 확인(`confirm`)·테이블 재구축은 초기화하지 않음
- 서버는 수정 전 코드로 기동 중이었음(재기동 16:27:00, 수정 저장 16:27:13)

## 해결 방법

세 진입점이 공통 `_start_vectorization` 사용: 이전 실행 취소(`cancel_all_jobs`) → 플래그 초기화 → 새 실행. 업로드 중 이전 실행이 끝까지 겹쳐 돌던 문제도 함께 해소. PR 백엔드 #172.

## 남은 한계

- 취소는 DB 상태만 바꿔 실행 중 단계는 다음 확인 지점까지 수 초 더 돎
- 근본 해법은 실행 ID + job 상태 기준 취소
