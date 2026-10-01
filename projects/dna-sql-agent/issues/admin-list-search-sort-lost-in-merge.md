---
type: troubleshooting
project: dna-sql-agent
date: 2026-10-01
resolved: true
root-cause: "PR #160 머지(8bf55b1a)에서 paged 라우트의 search·sort 파라미터가 빠짐"
related: [admin]
tags: [git, merge, regression]
---

# 관리자 연결·시스템 목록 이름 검색·정렬 미동작

## 증상

DB 연결 관리·시스템 목록에서 이름 검색과 이름순/최신순 정렬이 반영되지 않음. 프론트는 `search`·`sort` 를 보내는데 서버가 무시.

## 근본 원인

- 7/21 `78c27f7c` 에서 `/connections/paged`·`/systems/paged` 에 `search`·`sort` 추가(crud 도 지원)
- 9/21 PR #160(`feat/bird-bench-0619`) 머지 커밋 `8bf55b1a` 에서 두 라우트의 파라미터만 사라짐. 해당 브랜치는 main 머지 충돌을 "keep ours" 로 해결한 이력(`4e31061f`)이 있음
- `git log -S` 는 머지 커밋을 기본으로 보지 않아 처음엔 안 잡혔고, `git log -m -S` 로 확인

## 해결 방법

두 라우트에 파라미터 복구. 같은 머지에서 `78c27f7c` 의 나머지 변경은 온전함을 줄 단위 대조로 확인.

## 참고

- [[knowledge/troubleshooting/merge-keep-ours-silently-reverts-other-features]]
