#!/bin/bash
# ============================================================
# 새 프로젝트 생성
# 위키 프로젝트 폴더 + (선택) 프로젝트 repo에 커맨드 설정
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TODAY=$(date +%Y-%m-%d)

# ── wiki config 읽기 ──────────────────────────────────────────\

echo $SCRIPT_DIR

if [ -f "$SCRIPT_DIR/.wiki-config" ]; then
    source "$SCRIPT_DIR/.wiki-config"
else
    WIKI_ROOT="$SCRIPT_DIR"
    WIKI_NAME=$(basename "$WIKI_ROOT")
fi

# ── 입력 ──────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║       $WIKI_NAME — 새 프로젝트 생성               ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

if [ -n "$1" ]; then
    PROJECT_NAME="$1"
else
    read -rp "프로젝트 이름 (kebab-case): " PROJECT_NAME
fi

if [ -z "$PROJECT_NAME" ]; then
    echo "❌ 프로젝트 이름을 입력해주세요."
    exit 1
fi

read -rp "프로젝트 한 줄 목표 (엔터로 건너뛰기): " PROJECT_GOAL
PROJECT_GOAL="${PROJECT_GOAL:-TODO: 프로젝트 목표를 작성하세요}"

read -rp "기술 스택 (쉼표 구분, 예: nextjs,supabase — 엔터로 건너뛰기): " STACK_INPUT
if [ -n "$STACK_INPUT" ]; then
    STACK_YAML=$(echo "$STACK_INPUT" | sed 's/,/, /g' | sed 's/^/[/' | sed 's/$/]/')
else
    STACK_YAML="[]"
fi

read -rp "GitHub repo URL (엔터로 건너뛰기): " REPO_URL
read -rp "프로젝트 repo 로컬 경로 (엔터로 건너뛰기, 나중에 link-repo.sh로 연결 가능): " REPO_PATH

WIKI_PROJECT="$WIKI_ROOT/projects/$PROJECT_NAME"

# ── 중복 확인 ─────────────────────────────────────────────────

if [ -d "$WIKI_PROJECT" ]; then
    echo ""
    echo "⚠️  이미 존재합니다: projects/$PROJECT_NAME"
    read -rp "기존 폴더에 빠진 파일만 추가할까요? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "취소되었습니다."
        exit 0
    fi
fi

echo ""
echo "📁 위키 프로젝트 생성 중..."
echo ""

mkdir -p "$WIKI_PROJECT"/{decisions,sessions,issues,raw}

# ── overview.md ───────────────────────────────────────────────
if [ ! -f "$WIKI_PROJECT/overview.md" ]; then
cat > "$WIKI_PROJECT/overview.md" << EOF
---
type: project-overview
project: $PROJECT_NAME
created: $TODAY
updated: $TODAY
status: active
stack: $STACK_YAML
repo: "$REPO_URL"
goal: "$PROJECT_GOAL"
---

# $PROJECT_NAME

## 목표

> $PROJECT_GOAL

## 기술 스택

| 영역 | 기술 | 선택 근거 |
|------|------|----------|
| Frontend | | |
| Backend | | |
| DB | | |
| Infra/Deploy | | |

## 주요 의사결정

_(ADR 추가 시 갱신)_

## 현재 상태

→ [[projects/$PROJECT_NAME/status|상세 상태]] 참조

## 관련 지식

_(관련 knowledge/ 페이지 링크)_
EOF
echo "  ✅ overview.md"
fi

# ── status.md ─────────────────────────────────────────────────
if [ ! -f "$WIKI_PROJECT/status.md" ]; then
cat > "$WIKI_PROJECT/status.md" << EOF
---
type: project-status
project: $PROJECT_NAME
updated: $TODAY
phase: setup
---

# $PROJECT_NAME — 현재 상태

## 현재 단계

🔧 **초기 설정** 단계

## 완료된 것

- [x] 위키 프로젝트 폴더 생성

## 진행 중

- [ ] 

## 다음 할 일

- [ ] 

## 블로커

_(없음)_

## 메모

EOF
echo "  ✅ status.md"
fi

# ── architecture.md ───────────────────────────────────────────
if [ ! -f "$WIKI_PROJECT/architecture.md" ]; then
cat > "$WIKI_PROJECT/architecture.md" << EOF
---
type: architecture
project: $PROJECT_NAME
created: $TODAY
updated: $TODAY
---

# $PROJECT_NAME — 아키텍처

## 시스템 개요

> 전체 구조를 한 문단으로 설명.

## 기술 스택 상세

| 카테고리 | 기술 | 버전 | 용도 |
|---------|------|------|------|
| | | | |

## 디렉토리 구조

\`\`\`
(프로젝트 repo의 주요 디렉토리 구조)
\`\`\`

## 데이터 흐름

> 사용자 요청이 어떻게 흐르는지.

## 외부 의존성

| 서비스 | 용도 | 비용 | 대안 |
|--------|------|------|------|
| | | | |

## 관련 의사결정

_(ADR 링크)_
EOF
echo "  ✅ architecture.md"
fi

# ── decisions/000-template.md ─────────────────────────────────
if [ ! -f "$WIKI_PROJECT/decisions/000-template.md" ]; then
cat > "$WIKI_PROJECT/decisions/000-template.md" << EOF
---
type: decision-record
project: $PROJECT_NAME
date: $TODAY
status: template
superseded-by: ""
tags: []
---

# ADR-000: 템플릿 (참조용)

> 새 ADR 작성 시 이 형식을 따른다. 파일명: \`NNN-제목.md\`

## 맥락

어떤 상황에서 이 결정이 필요했는가.

## 선택지

### 옵션 A: (이름)
- **장점:** 
- **단점:** 
- **비용/노력:** 

### 옵션 B: (이름)
- **장점:** 
- **단점:** 
- **비용/노력:** 

## 결정

**옵션 X를 선택한다.**

## 근거

왜 이 선택이 현재 상황에서 최선인지.

## 결과

- 알려진 트레이드오프
- 향후 재검토 시점
- 영향받는 다른 컴포넌트

## 참고 자료

- 
EOF
echo "  ✅ decisions/000-template.md"
fi

# ── sessions/000-template.md ──────────────────────────────────
if [ ! -f "$WIKI_PROJECT/sessions/000-template.md" ]; then
cat > "$WIKI_PROJECT/sessions/000-template.md" << EOF
---
type: session-log
project: $PROJECT_NAME
date: $TODAY
duration: 
focus: "템플릿 (참조용)"
tools-used: [claude-code]
outcome: success
---

# YYYY-MM-DD — 작업 주제

> 새 세션 로그 파일명: \`YYYY-MM-DD-주제.md\`

## 목표

이 세션에서 달성하려 한 것.

## 수행한 작업

1. 

## 핵심 결정

- **결정 1:** 무엇을 왜 선택했는가
  → ADR: [[decisions/NNN-제목]]

## 배운 것

- 

## 문제 & 해결

- **문제:** 
- **원인:** 
- **해결:** 
  → 이슈: [[issues/이슈명]]

## 다음 할 일

- [ ] 

## 효과적이었던 프롬프트

\`\`\`
\`\`\`
EOF
echo "  ✅ sessions/000-template.md"
fi

# ── issues/000-template.md ────────────────────────────────────
if [ ! -f "$WIKI_PROJECT/issues/000-template.md" ]; then
cat > "$WIKI_PROJECT/issues/000-template.md" << EOF
---
type: troubleshooting
project: $PROJECT_NAME
date: $TODAY
resolved: false
root-cause: ""
related: []
tags: []
---

# 문제 제목 (참조용)

> 새 이슈 파일명: \`문제-요약.md\`

## 증상

\`\`\`
(에러 메시지)
\`\`\`

## 환경

- **OS:** 
- **런타임:** 
- **관련 패키지:** 
- **재현 조건:** 

## 시도한 것들

1. ❌ 
2. ✅ 

## 근본 원인



## 해결 방법

\`\`\`
\`\`\`

## 예방책



## 관련 페이지

- [[knowledge/troubleshooting/관련-일반-문제]]
EOF
echo "  ✅ issues/000-template.md"
fi

# ── raw/README.md ─────────────────────────────────────────────
if [ ! -f "$WIKI_PROJECT/raw/README.md" ]; then
cat > "$WIKI_PROJECT/raw/README.md" << EOF
# $PROJECT_NAME — Raw Sources

이 폴더에는 프로젝트 관련 원본 자료를 보관한다.
**LLM은 이 폴더의 파일을 절대 수정하지 않는다.**

## 보관 대상

- 초기 요구사항 문서
- 참고 디자인 스크린샷
- CLAUDE.md 스냅샷 (중요 변경 시)
- 외부 참고 자료
EOF
echo "  ✅ raw/README.md"
fi

echo ""
echo "📂 위키 프로젝트 완료: projects/$PROJECT_NAME"

# ── Repo 연결 ─────────────────────────────────────────────────

if [ -n "$REPO_PATH" ] && [ -d "$REPO_PATH" ]; then
    echo ""
    "$SCRIPT_DIR/link-repo.sh" "$PROJECT_NAME" "$REPO_PATH"
elif [ -n "$REPO_PATH" ]; then
    echo ""
    echo "⚠️  repo를 찾을 수 없습니다: $REPO_PATH"
    echo "   나중에: ./link-repo.sh $PROJECT_NAME <repo경로>"
fi

# ── _meta 갱신 ────────────────────────────────────────────────

LOG="$WIKI_ROOT/_meta/log.md"
if [ -f "$LOG" ]; then
    {
        echo ""
        echo "## [$TODAY] init | $PROJECT_NAME 프로젝트 생성"
        echo ""
        echo "- 위키 프로젝트 폴더 생성: projects/$PROJECT_NAME"
        echo "- 목표: $PROJECT_GOAL"
        [ -n "$STACK_INPUT" ] && echo "- 스택: $STACK_INPUT"
    } >> "$LOG"
    echo "📝 _meta/log.md 갱신"
fi

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✅ $PROJECT_NAME 생성 완료"
echo "══════════════════════════════════════════════════"
echo ""
if [ -z "$REPO_PATH" ] || [ ! -d "$REPO_PATH" ]; then
    echo "  💡 repo 준비되면: ./link-repo.sh $PROJECT_NAME <repo경로>"
    echo ""
fi
