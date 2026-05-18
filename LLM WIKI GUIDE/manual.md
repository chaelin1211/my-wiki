# LLM Wiki 사용 매뉴얼

Claude Code 프로젝트 지식 관리를 위한 Obsidian Wiki 시스템.

---

## 개요

이 시스템은 세 가지 도구로 구성됩니다.

| 스크립트 | 역할 | 실행 시점 |
|---------|------|----------|
| `setup.sh` | Vault 초기 생성 | 최초 1회 |
| `new-project.sh` | 프로젝트 폴더 + 템플릿 생성 | 프로젝트 시작할 때 |
| `link-repo.sh` | repo에 Claude Code 커맨드 연결 | repo가 준비된 후 |

시스템의 핵심 아이디어: LLM이 위키를 생성·관리하고, 인간은 소싱·탐색·의사결정에 집중한다. 위키가 프로젝트마다 쌓이면서 프로젝트를 관통하는 지식이 축적된다.

---

## 1. 최초 설정

### 1-1. Vault 생성

```bash
chmod +x setup.sh
./setup.sh
```

위키 이름과 경로를 물어봅니다. 입력하면 아래 구조가 자동 생성됩니다.

```
{위키이름}/
├── _schema/                  ← 운영 규칙 & 템플릿
│   ├── CLAUDE.md             ← LLM이 따르는 위키 규칙 전문
│   ├── conventions.md        ← 태그, 콜아웃, 커밋 메시지 규약
│   └── templates/            ← 페이지 유형별 템플릿 6종
│
├── _meta/                    ← 네비게이션 & 현황
│   ├── index.md              ← 위키 전체 카탈로그
│   ├── log.md                ← 시간순 작업 기록
│   └── dashboard.md          ← Dataview 대시보드
│
├── projects/                 ← 프로젝트별 기록
├── knowledge/                ← 프로젝트 횡단 지식
│   ├── tools/                ← 도구·라이브러리
│   ├── patterns/             ← 재사용 패턴
│   ├── troubleshooting/      ← 공통 문제 해결
│   └── prompting/            ← Claude Code 프롬프팅 노하우
│
├── raw/                      ← 원본 소스 (불변)
│   ├── docs/
│   ├── articles/
│   └── assets/
│
├── new-project.sh            ← 여기에 복사
├── link-repo.sh              ← 여기에 복사
└── .wiki-config              ← 자동 생성된 내부 설정
```

### 1-2. 스크립트 배치

`new-project.sh`와 `link-repo.sh`를 vault 루트에 복사합니다.

```bash
cp new-project.sh link-repo.sh /your/vault/path/
cd /your/vault/path/
chmod +x new-project.sh link-repo.sh
```

### 1-3. Obsidian 플러그인 설치

Obsidian에서 vault를 열고 아래 플러그인을 설치합니다.

| 플러그인             | 필수 여부 | 용도                     |
| ---------------- | ----- | ---------------------- |
| **Dataview**     | 필수    | dashboard.md 동적 쿼리     |
| **obsidian-git** | 필수    | 자동 버전 관리 (5~10분 간격 권장) |
| **Templater**    | 권장    | 수동 페이지 생성 시 템플릿 삽입     |
| **Tag Wrangler** | 권장    | 태그 리네이밍·병합             |

설정 후 `_meta/dashboard.md`를 Obsidian 시작 페이지로 지정하면 vault를 열 때마다 현황판이 보입니다.

---

## 2. 새 프로젝트 시작

### 2-1. 프로젝트 생성

vault 폴더에서 실행합니다.

```bash
./new-project.sh
```

대화형으로 물어봅니다:

```
프로젝트 이름 (kebab-case): my-saas-app
프로젝트 한 줄 목표: 개인용 SaaS 보일러플레이트
기술 스택 (쉼표 구분): nextjs,supabase,tailwind
GitHub repo URL: https://github.com/user/my-saas-app
프로젝트 repo 로컬 경로: ~/projects/my-saas-app
```

모든 항목은 엔터로 건너뛸 수 있습니다. 이름만 필수입니다.

생성되는 구조:

```
projects/my-saas-app/
├── overview.md               ← 프로젝트 진입점 (목표, 스택, ADR 링크)
├── status.md                 ← 현재 상태, 진행률, 다음 할 일
├── architecture.md           ← 아키텍처, 의존성, 데이터 흐름
├── decisions/
│   └── 000-template.md       ← ADR 형식 참조
├── sessions/
│   └── 000-template.md       ← 세션 로그 형식 참조
├── issues/
│   └── 000-template.md       ← 이슈 기록 형식 참조
└── raw/
    └── README.md
```

각 폴더의 `000-template.md`는 Claude Code가 새 파일을 만들 때 형식 참조로 사용합니다. 삭제하지 마세요.

### 2-2. repo 연결 (나중에)

프로젝트 생성 시 repo 경로를 건너뛰었다면, repo가 준비된 후 연결합니다.

```bash
# 방법 1: 인자로 직접
./link-repo.sh my-saas-app ~/projects/my-saas-app

# 방법 2: 대화형 (프로젝트 목록 표시)
./link-repo.sh
```

이 스크립트가 하는 일:

- `프로젝트repo/.claude/commands/`에 슬래시 커맨드 5종 생성
- `프로젝트repo/CLAUDE.md`에 Wiki Integration 섹션 추가 (기존 내용 보존)

---

## 3. 일상 워크플로우

### 3-1. 세션 시작

프로젝트 디렉토리에서 Claude Code를 실행하고:

```
/wiki-start
```

Claude Code가 수행하는 것:
- `status.md`를 읽어 현재 상태 파악
- 최근 세션 로그 3개로 맥락 복원
- 미해결 이슈 확인
- 관련 knowledge/ 참조
- 현재 상태와 추천 다음 작업을 보고

### 3-2. 작업 중 — 기술 결정 기록

기술 선택, 아키텍처 변경 등 의사결정 후:

```
/wiki-decision
```

Claude Code가 수행하는 것:
- `decisions/`에 ADR 파일 생성 (번호 자동 부여)
- `overview.md`와 `architecture.md`에 링크 추가
- 관련 `knowledge/tools/` 페이지 갱신 또는 생성
- `log.md`에 기록

### 3-3. 작업 중 — 문제 해결 기록

버그나 문제를 해결한 후:

```
/wiki-issue
```

Claude Code가 수행하는 것:
- `issues/`에 문제 해결 기록 생성
- 범용적 문제면 `knowledge/troubleshooting/`에도 일반화 버전 작성
- 관련 도구의 `knowledge/tools/` 페이지에 주의사항 추가
- `log.md`에 기록

### 3-4. 세션 종료

작업을 마칠 때:

```
/wiki-end
```

Claude Code가 수행하는 것:
- `sessions/`에 세션 로그 생성
- `status.md` 갱신 (완료 항목 체크, 다음 할 일 업데이트)
- 세션 중 의사결정이나 이슈가 기록되지 않았으면 추가 생성
- 범용 지식이 있으면 `knowledge/`에 추가
- `log.md`와 `index.md` 갱신

### 3-5. 위키 점검 (주 1회 권장)

```
/wiki-lint
```

Claude Code가 수행하는 것:
- 프론트매터 규약 위반 점검
- 깨진 링크 탐지
- `status.md` 정합성 확인
- 미해결 이슈 현황 확인
- `knowledge/` 페이지 최신성 확인
- 수정 제안 후 동의 시 일괄 적용
- `log.md`에 점검 결과 기록

---

## 4. 커맨드 요약

| 커맨드 | 시점 | 핵심 동작 |
|--------|------|----------|
| `/wiki-start` | 세션 시작 | 상태 읽기 → 맥락 복원 → 다음 작업 추천 |
| `/wiki-end` | 세션 종료 | 세션 로그 → 상태 갱신 → knowledge 축적 |
| `/wiki-decision` | 기술 결정 후 | ADR 작성 → overview/architecture 갱신 |
| `/wiki-issue` | 문제 해결 후 | 이슈 기록 → knowledge 교차 참조 |
| `/wiki-lint` | 주 1회 | 전체 점검 → 수정 제안 → 일괄 적용 |

---

## 5. 지식 순환 구조

이 시스템의 핵심 가치는 **프로젝트 간 지식 순환**에 있습니다.

```
프로젝트 A에서 문제 발생
  → issues/에 기록
  → knowledge/troubleshooting/에 일반화
  
프로젝트 B 시작
  → /wiki-start가 knowledge/ 참조
  → 같은 문제를 미리 방지
```

```
프로젝트 A에서 Supabase 도입
  → /wiki-decision으로 ADR 작성
  → knowledge/tools/supabase.md 생성
  
프로젝트 B에서 Supabase 재사용
  → 이전 경험, 주의사항, 패턴이 이미 축적
```

`knowledge/` 폴더가 이 순환의 허브입니다:

| 폴더 | 축적되는 것 |
|------|-----------|
| `knowledge/tools/` | 도구별 사용법, 주의사항, 설정 패턴 |
| `knowledge/patterns/` | 반복 사용하는 코드 패턴, 아키텍처 기법 |
| `knowledge/troubleshooting/` | 프로젝트 무관하게 재발하는 문제와 해법 |
| `knowledge/prompting/` | Claude Code를 효과적으로 쓰는 노하우 |

---

## 6. Obsidian 활용 팁

### Graph View

Obsidian 그래프 뷰로 위키의 연결 구조를 시각화할 수 있습니다. 허브 역할을 하는 페이지(많은 링크가 연결된 노드)와 고아 페이지(연결이 없는 노드)를 한눈에 파악할 수 있습니다.

### Dashboard

`_meta/dashboard.md`가 Dataview 플러그인으로 자동 생성하는 뷰:

- 활성 프로젝트 목록 (스택, 상태, 최근 갱신일)
- 최근 세션 10건
- 미해결 이슈 목록
- 최근 의사결정
- Knowledge 최근 갱신
- 도구 목록

### 소스 관리

`raw/` 폴더는 불변입니다. Web Clipper로 아티클을 저장하거나, 참고 자료를 넣을 때 이 폴더를 사용합니다. LLM은 여기를 읽기만 하고 절대 수정하지 않습니다.

### Git 버전 관리

obsidian-git 플러그인으로 5~10분 간격 자동 커밋을 설정하면, LLM이 대규모 수정을 할 때도 롤백이 가능합니다.

---

## 7. 파일별 프론트매터 레퍼런스

모든 위키 페이지에는 YAML 프론트매터가 있습니다. Dataview 쿼리와 LLM 탐색에 사용됩니다.

### project-overview

```yaml
---
type: project-overview
project: my-saas-app
created: 2026-04-15
updated: 2026-04-15
status: active          # active | paused | completed | abandoned
stack: [nextjs, supabase]
repo: "https://github.com/..."
goal: "프로젝트 목표"
---
```

### session-log

```yaml
---
type: session-log
project: my-saas-app
date: 2026-04-15
duration: 2h
focus: "결제 기능 구현"
tools-used: [claude-code, vercel-cli]
outcome: success        # success | partial | blocked
---
```

### decision-record

```yaml
---
type: decision-record
project: my-saas-app
date: 2026-04-15
status: accepted        # proposed | accepted | deprecated | superseded
superseded-by: ""
tags: [payment, stripe]
---
```

### troubleshooting

```yaml
---
type: troubleshooting
project: my-saas-app
date: 2026-04-15
resolved: true
root-cause: "설명"
related: ["[[knowledge/troubleshooting/관련문제]]"]
tags: [stripe, webhook]
---
```

### tool (knowledge)

```yaml
---
type: tool
created: 2026-04-15
updated: 2026-04-15
tags: [payment, saas]
used-in: [my-saas-app, another-project]
---
```

### pattern (knowledge)

```yaml
---
type: pattern
created: 2026-04-15
updated: 2026-04-15
tags: [auth, security]
used-in: [my-saas-app]
---
```

---

## 8. FAQ

**Q: 기존 프로젝트에도 적용할 수 있나요?**
A: `./new-project.sh`로 위키 프로젝트를 만들고, `./link-repo.sh`로 기존 repo에 커맨드를 연결하면 됩니다. Claude Code에서 `/wiki-start` 후 기존 코드베이스를 분석해서 overview, architecture, status를 채워달라고 요청하세요.

**Q: 위키가 커지면 LLM이 다 읽을 수 있나요?**
A: `_meta/index.md`가 카탈로그 역할을 합니다. LLM은 인덱스를 먼저 읽고 관련 페이지만 선택적으로 읽습니다. 200+ 페이지가 넘으면 qmd 같은 로컬 검색 엔진 도입을 고려하세요.

**Q: 여러 프로젝트에서 같은 위키를 써도 되나요?**
A: 이 시스템이 정확히 그렇게 설계되었습니다. 모든 프로젝트가 하나의 vault를 공유하고, `knowledge/`를 통해 지식이 교차됩니다.

**Q: 커맨드를 커스터마이즈하고 싶어요.**
A: `프로젝트repo/.claude/commands/` 안의 md 파일을 직접 편집하면 됩니다. 이 파일들이 Claude Code에게 전달되는 지시사항입니다.

**Q: 템플릿을 바꾸고 싶어요.**
A: `_schema/templates/`의 파일을 수정하세요. 프로젝트별 `000-template.md`도 함께 수정하면 일관성이 유지됩니다.

**Q: setup.sh를 다시 실행하면 어떻게 되나요?**
A: 기존 파일은 덮어쓰지 않고, 없는 파일만 생성합니다. 안전하게 재실행 가능합니다.
