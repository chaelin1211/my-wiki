---
type: knowledge
category: troubleshooting
date: 2026-10-01
tags: [git, merge, regression, code-review]
---

# 오래된 브랜치 머지에서 다른 기능이 조용히 되돌아간다 — keep ours 와 git log -m

## 문제 패턴

오래 살아 있는 기능 브랜치가 main 을 여러 번 머지하면서 충돌을 "keep ours" 로 풀면, 그 사이 main 에
들어온 다른 사람의 변경이 브랜치 쪽 옛 코드로 덮인다. 이후 그 브랜치를 main 에 머지하면 해당 기능이
**에러 없이** 사라진다. 프론트는 여전히 파라미터를 보내고 서버는 조용히 무시하는 식이라 한참 뒤에 발견된다.

## 추적 방법

- 기능이 들어온 커밋을 찾는다: `git log -S '<추가된 줄>' -- <파일>`
- 그 커밋이 현재 브랜치에 포함돼 있는지: `git merge-base --is-ancestor <커밋> HEAD`
- 포함돼 있는데 코드가 없다면 머지에서 빠진 것. `git log -S` 는 머지 커밋 diff 를 기본으로 보지 않으므로
  **`git log -m -S '<줄>' -- <파일>`** 로 찾는다
- 머지 직전 main(첫 번째 부모)과 머지 결과를 비교: `git diff <머지>^1 <머지> -- <파일>`
- 그 커밋의 다른 변경도 같이 사라졌는지 줄 단위로 대조한다(추가된 줄 목록을 현재 소스에서 grep)

## 예방

- 큰 머지 PR 은 "의도하지 않은 삭제" 를 따로 리뷰한다(`git diff main...branch --stat` 의 삭제 줄)
- 충돌 해결에서 일괄 keep ours 금지

## 출처

- [[projects/dna-sql-agent/issues/admin-list-search-sort-lost-in-merge]]
