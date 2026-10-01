---
tags: [git, workflow, pitfall]
related: []
---

# stale 로컬 브랜치 기준 `git diff`가 이미 머지된 커밋을 새 변경사항으로 보여줌

## 증상

`git diff main...feature-branch` 또는 `git log main..feature-branch`로 "이 브랜치에 뭐가
새로 들어있나" 확인했는데, 실제로는 이미 `origin/main`에 머지된 커밋(다른 PR로)까지
목록에 나옴. 그걸 보고 "새 변경사항"이라고 사용자에게 잘못 설명하게 됨.

## 원인

로컬 `main` 브랜치가 `git fetch`를 오래 안 해서 `origin/main`보다 뒤처져 있는 상태.
`git diff main...feature-branch`는 **로컬 `main` ref** 기준으로 계산되므로, 로컬 main이
모르는(= 로컬 기준으로는 아직 안 머지된) 커밋은 전부 "feature-branch에만 있는 새 변경사항"
으로 잡힌다. 실제로는 그 커밋들이 이미 `origin/main`에 다른 PR로 머지되어 있을 수 있다.

## 확인 방법

```bash
git fetch origin main
git rev-list --count main..origin/main   # 0보다 크면 로컬 main이 뒤처진 상태
git merge-base --is-ancestor <commit> origin/main && echo "이미 origin/main에 있음"
```

## 해결

공유 브랜치(main 등)를 기준으로 diff/log를 볼 때는 **먼저 `git fetch`**. 로컬 `main`이
아니라 `origin/main`을 기준으로 비교:

```bash
git fetch origin main
git diff origin/main...feature-branch
```

`gh pr create --base main`처럼 GitHub API를 통하는 명령은 서버가 실제 원격 브랜치를 기준으로
계산하므로 이 문제와 무관하다 — 문제는 **로컬에서 직접 diff/log를 찍어서 사람에게 설명할
때** 발생한다.

## 예방책

- 공유 브랜치 관련 diff/log를 보여주기 전엔 습관적으로 `git fetch` 먼저
- "이 브랜치에 새로 뭐가 들어있나"를 물어볼 땐 로컬 ref 이름이 아니라 `origin/<branch>`를
  기준으로 삼기

## 관련 페이지

- [[projects/dna-sql-agent/sessions/2026-07-29-pyi-leak-fix-and-secret-hygiene-audit]]
