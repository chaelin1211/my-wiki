---
type: session-log
project: dna-sql-agent
date: 2026-07-29
duration: ""
focus: "Nuitka .pyi 유출 실제 수정 + 시크릿 관리 점검 (.env git 추적, JWT fallback)"
tools-used: [claude-code]
outcome: success
---

# 2026-07-29 — Nuitka .pyi 유출 실제 수정 + 시크릿 관리 점검

## 목표

전날([[2026-07-28-self-hosted-runner-disk-full-and-image-hardening]]) 발견한 `.pyi` 스텁
유출 문제를 실제로 고치고, 이어서 나온 "암호화 키/시크릿 관리" 논의를 계기로 `.env` 취급
전반을 점검.

## 수행한 작업

1. `requirements.txt` 최종 이미지 격리(옵션 C, context 스테이지)는 리스크 대비 비용이 안
   맞아 적용 보류하기로 재확인 (전날 이미 기록).
2. `.dockerignore`에 `frontend`, `/*.md`(루트 한정) 추가 확인 — `src/dna/tools/*.md`(화면
   표시용 매뉴얼)는 루트가 아니라서 영향 없음, 안전함을 확인.
3. Python AST로 `.pyi` 유출 위험 패턴(함수 기본 인자값 / 모듈·클래스 상수)을 정밀 스캔.
   `schema.py`(DB DDL 전체), `vectorization/prompts.py`(LLM 시스템 프롬프트 전체),
   `sql_collectors/summarizer.py`, `bi_slide/template_selector.py`,
   `relation_info_generator.py`(FK 추론 정규식) 확인.
4. `feat/nuitka` 브랜치를 `main`으로 PR #125 생성. **실수**: 로컬 `main`이 origin보다 11개
   커밋 뒤처진 상태로 `git diff main...feat/nuitka`를 봐서, 이미 `main`에 머지된 relation
   FAQ/join hint 커밋(PR #123, #124)이 새 변경사항인 것처럼 잘못 설명함. 사용자가 직접 정정.
   → 지식화: [[knowledge/troubleshooting/git-diff-stale-local-branch-shows-merged-commits-as-new]]
5. Nuitka 공식 옵션 확인(`python -m nuitka --help`) 결과 `--no-pyi-file`로 `.pyi` 생성 자체를
   차단 가능함을 발견 (`--no-pyi-stubs`는 stubgen 방식만 끄는 것이라 부족). `Dockerfile`의
   nuitka 컴파일 커맨드에 `--no-pyi-file` 추가, `docs/nuitka-build-design.md` §3.4에 기록
   (문서는 사용자가 직접 다듬음).
   → 지식화: [[knowledge/patterns/nuitka-no-pyi-file-prevents-stub-leak]]
6. `.env`/암호화 키 관리 논의 중 실제 코드 확인:
   - `DB_ENCRYPTION_KEY`(Fernet) — 앱 자체 Postgres DB에 저장하는 **타겟 DB 커넥션 정보 +
     LLM 커넥션 자격증명**을 암호화하는 키. 분실 시 저장된 모든 커넥션 정보 복구 불가.
   - `src/dna/auth/jwt_utils.py:15` — `JWT_SECRET_KEY` 환경변수가 없으면 하드코딩된
     `"default-secret-change-me"`로 조용히 fallback. **미수정 상태로 발견만 함.**
     → 이슈: [[issues/jwt-secret-key-hardcoded-fallback-default]]
   - `git status`/`git log --all -- .env` 확인 중 `.env`가 `origin/main`,
     `origin/feat/nuitka`에 커밋되어 있는 걸 보고 처음엔 심각한 유출로 오판해 이슈 문서까지
     작성했으나, **사용자 확인 결과 private 레포 안에서 팀 공유 목적으로 의도적으로 커밋해둔
     것**이었음 (공개 레포 유출이 아님). 작성했던 이슈 문서 삭제·정정.

## 핵심 결정

- **결정:** `.pyi` 스텁 생성을 `--no-pyi-file`로 원천 차단한다 (Nuitka 빌드 커맨드에 반영).
  → ADR: [[decisions/027-nuitka-source-compilation]] (결과 섹션에 추가 기록)
- **미결정 (다음 세션 논의 필요):** `schema.py`/`vectorization/prompts.py` 등 모듈 상수로
  박힌 민감 값은 `--no-pyi-file`로도 `.so` 바이너리 안에서 `strings`로 여전히 추출 가능 —
  데이터 파일 분리 + 암호화 여부는 아직 미결정.

## 배운 것

- **`git diff`/`git log`로 공유 브랜치(main 등)를 기준 삼기 전엔 반드시 `git fetch`부터.**
  로컬 ref가 stale하면 이미 머지된 커밋을 새 변경사항으로 오인해서 사용자에게 잘못된 정보를
  전달하게 됨 — 이번에 실제로 그렇게 해서 사용자를 화나게 만듦.
- Nuitka `--no-pyi-file`과 `--no-pyi-stubs`는 이름이 비슷해도 동작이 다름. `--no-pyi-file`이
  파일 생성 자체를 막는 옵션, `--no-pyi-stubs`는 생성 *방식*(stubgen 사용 여부)만 바꿈 —
  후자만 써서는 유출이 안 막힘.
- 파일이 git에 커밋돼 있다고 바로 "유출/사고"로 단정하면 안 됨 — private 레포 안에서
  팀 공유 목적으로 의도적으로 커밋해두는 경우도 있음(`.env` 사례). 판단하기 전에 레포가
  private인지, 그 팀의 공유 관례가 뭔지부터 확인하고, 애매하면 사용자에게 직접 확인.

## 문제 & 해결

- **문제:** `JWT_SECRET_KEY` 환경변수가 없으면 하드코딩된 기본값으로 조용히 fallback.
- **원인:** `jwt_utils.py`가 `os.getenv("JWT_SECRET_KEY", "default-secret-change-me")`로
  작성돼 있어, 배포 시 이 값을 빠뜨려도 에러 없이 기동됨.
- **해결:** 미해결. → [[issues/jwt-secret-key-hardcoded-fallback-default]]

## 다음 할 일

- [ ] `jwt_utils.py`의 `JWT_SECRET_KEY` 하드코딩 기본값 fallback 제거 (없으면 기동 실패시키는
      방향으로)
- [ ] `schema.py`/`prompts.py` 등 모듈 상수 데이터 파일 분리·암호화 여부 결정 (PR #125 논의)
- [ ] PR #125 정리 (사용자가 직접 처리하겠다고 함)

## 효과적이었던 프롬프트

```
python3 -m nuitka --help 2>/dev/null | grep -i -B2 -A2 "pyi"   # 옵션 이름 추측 대신 실제 --help로 확인
git log --all --oneline -- .env                                  # 파일의 git 추적 이력 전체 확인
```
