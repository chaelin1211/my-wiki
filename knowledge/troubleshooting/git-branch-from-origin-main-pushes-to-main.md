---
type: troubleshooting
tags: [git, branch, push, upstream]
created: 2026-11-03
updated: 2026-11-03
---

# `origin/main`에서 만든 브랜치를 push했더니 원격 main이 갱신됨

## 증상

`git push -u origin <새브랜치>` 후 PR을 만들려니 "No commits between main and <새브랜치>". 원격 main reflog에 `update by push`가 남고, 새 브랜치 커밋이 리뷰 없이 main에 올라가 있다.

## 원인

`git switch -c <새브랜치> origin/main`은 새 브랜치가 `origin/main`을 추적하도록 설정한다. 이 상태의 push가 추적 대상인 main을 갱신했다(main 브랜치 보호 없음).

## 예방

- 브랜치 생성: `git switch -c <이름> --no-track origin/main`
- 첫 push: `git push -u origin <이름>:<이름>`처럼 대상 이름 명시
- push 전 확인: `git config branch.<이름>.merge`가 `refs/heads/<이름>`인지
- 저장소에 main 브랜치 보호 규칙을 걸면 실수가 막힌다.

## 사고 후 선택지

- `git push --force-with-lease=main:<잘못 올라간 sha> origin <원래 sha>:main`으로 되돌린 뒤 PR (그사이 다른 push가 있으면 실패해 남의 커밋 보호). 이미 받아 간 사람은 main을 다시 맞춰야 함.
- 그대로 두기.

## 사례

- [[projects/dna-sql-agent/sessions/2026-11-03-altibase-korean-charset-row-limit-report]] (그대로 두기로 결정)
