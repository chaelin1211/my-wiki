---
type: troubleshooting
date: 2026-06-17
tags: [git, filter-branch, history-rewrite]
related-projects: [dna-sql-agent-web]
---

# git filter-branch로 커밋된 파일 제거하기 — 범위는 커밋이 아니라 커밋 "구간"이다

## 핵심

`git filter-branch --index-filter` 는 지정한 **구간(`start..HEAD`)의 모든 커밋**에
같은 명령을 적용한다. "이 커밋에서 실수로 넣은 파일만 지운다"는 의도로 써도,
그 경로가 **이전 커밋부터 추적되던 파일**이라면 지정 커밋 시점부터 삭제된 것으로
히스토리가 재작성된다.

즉 `--index-filter` 의 대상은 "내가 지우려는 그 파일"이 아니라 "그 경로에 있는
모든 것 × 구간 내 모든 커밋"이다.

## 실행 전 확인

제거하려는 파일이 **해당 커밋에서 새로 추가된 것인지** 먼저 본다.

```bash
git show --name-status <커밋>
git stash -u          # 워킹트리 보호
```

이전 커밋부터 있던 파일이 같은 디렉토리에 섞여 있다면, 디렉토리를 통째로
`git rm --cached -r` 하지 말고 파일 단위로 지정한다.

## 이미 부작용이 난 경우

**워킹트리 복원:**

```bash
git checkout <원본파일이있던커밋> -- <파일경로>
git reset HEAD <파일경로>
```

**히스토리의 "삭제 diff" 제거** — 원본 blob 을 되살려 다시 재작성한다:

```bash
BLOB=$(git rev-parse <원본커밋>:<파일경로>)
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --force --index-filter \
  "git update-index --add --cacheinfo 100644,${BLOB},<파일경로>" \
  <문제커밋>^..HEAD
```

> [!tip]
> 신규 작업이라면 `filter-branch` 대신 `git filter-repo` 를 쓰는 편이 안전하다.
> Git 공식 문서도 `filter-branch` 사용을 권하지 않는다.

## 예방책

- 히스토리 재작성 전 `git stash -u` 로 워킹트리 저장
- 경로 지정은 디렉토리보다 파일 단위로
- 재작성 후 `git log --stat` 으로 의도하지 않은 삭제 diff 가 없는지 확인

## 관련 페이지

- [[projects/dna-sql-agent/issues/git-filter-branch-side-effect-tracked-files|dna-sql-agent-web: filter-branch 추적 파일 삭제 부작용 사례]]
- [[knowledge/troubleshooting/git-diff-stale-local-branch-shows-merged-commits-as-new]]
