---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-06-17
resolved: true
root-cause: "git filter-branch --index-filter가 지정 범위의 모든 커밋 인덱스에 명령을 적용하여, 이전 커밋에서 추적되던 파일도 삭제"
related: []
tags: [git, filter-branch]
---

# git filter-branch로 특정 커밋에서 파일 제거 시 기존 추적 파일 삭제 부작용

## 증상

`git filter-branch --index-filter 'git rm --cached --ignore-unmatch -r public/icons-unused'`를 실행 후,
이전 커밋에서 이미 추적되던 `public/icons-unused/icon-*.png` 등의 파일이 워킹트리에서 사라짐.
재작성된 커밋에서 해당 파일들이 `Bin 1642 -> 0 bytes` 형태로 삭제된 것으로 표시됨.

## 환경

- **OS:** macOS
- **Git:** 2.x
- **재현 조건:** 특정 커밋 이후 범위에 filter-branch 적용 시, 해당 범위 이전부터 추적되던 파일도 영향받음

## 시도한 것들

1. ✅ `git checkout <원본커밋> -- <파일경로>` 후 `git reset HEAD <파일>` 로 워킹트리 복원
2. ✅ blob hash를 `git rev-parse <커밋>:<경로>`로 조회 후 `git update-index --add --cacheinfo`로 filter-branch 재실행하여 히스토리 복원

## 근본 원인

`--index-filter`는 지정 범위(startCommit..HEAD)의 **모든** 커밋에 대해 명령을 순차 실행.
`git rm --cached -r public/icons-unused`는 해당 경로 아래 파일을 인덱스에서 제거하는데,
이전 커밋에서 추적되던 파일도 지정 커밋부터 "삭제"된 것으로 재작성됨.

## 해결 방법

**워킹트리 파일 복원:**
```bash
git checkout <원본파일이있던커밋> -- <파일경로>
git reset HEAD <파일경로>
```

**히스토리에서 "삭제 diff" 제거 (filter-branch 재실행):**
```bash
BLOB=$(git rev-parse <원본커밋>:<파일경로>)
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --force --index-filter \
  "git update-index --add --cacheinfo 100644,${BLOB},<파일경로>" \
  <문제커밋>^..HEAD
```

## 예방책

- filter-branch 전에 `git stash -u`로 워킹트리 저장
- 제거할 파일이 해당 커밋에서 **새로 추가된 것인지** 먼저 확인 (`git show --name-status <커밋>`)
- 이전 커밋에서 이미 추적되던 파일이 포함된 디렉토리를 통째로 `rm`하면 부작용 발생

## 관련 페이지

- [[knowledge/troubleshooting/git-filter-branch-remove-committed-files]]
