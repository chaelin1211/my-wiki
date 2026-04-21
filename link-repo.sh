#!/bin/bash
# ============================================================
# 위키 프로젝트 ↔ Repo 연결
# .claude/commands/ 5종 + CLAUDE.md Wiki Integration 추가
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── wiki config 읽기 ──────────────────────────────────────────

if [ -f "$SCRIPT_DIR/.wiki-config" ]; then
    source "$SCRIPT_DIR/.wiki-config"
else
    WIKI_ROOT="$SCRIPT_DIR"
    WIKI_NAME=$(basename "$WIKI_ROOT")
fi

# ── 입력 ──────────────────────────────────────────────────────

if [ -n "$1" ] && [ -n "$2" ]; then
    PROJECT_NAME="$1"
    REPO_PATH="$2"
else
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║       $WIKI_NAME — Repo 연결                      ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    echo "📂 등록된 위키 프로젝트:"
    echo ""
    for dir in "$WIKI_ROOT"/projects/*/; do
        if [ -d "$dir" ]; then
            name=$(basename "$dir")
            status=""
            if [ -f "$dir/overview.md" ]; then
                status=$(grep -m1 "^status:" "$dir/overview.md" 2>/dev/null | sed 's/status: *//' || echo "")
            fi
            printf "  • %-30s (%s)\n" "$name" "$status"
        fi
    done
    echo ""

    read -rp "프로젝트 이름: " PROJECT_NAME
    read -rp "프로젝트 repo 로컬 경로: " REPO_PATH
fi

# ── 검증 ──────────────────────────────────────────────────────

if [ -z "$PROJECT_NAME" ] || [ -z "$REPO_PATH" ]; then
    echo "❌ 사용법: ./link-repo.sh <프로젝트이름> <repo경로>"
    exit 1
fi

if [ ! -d "$WIKI_ROOT/projects/$PROJECT_NAME" ]; then
    echo "❌ 위키에 프로젝트가 없습니다: projects/$PROJECT_NAME"
    echo "   먼저 ./new-project.sh 로 생성하세요."
    exit 1
fi

# ~ 확장 처리
REPO_PATH="${REPO_PATH/#\~/$HOME}"

if [ ! -d "$REPO_PATH" ]; then
    echo "❌ repo를 찾을 수 없습니다: $REPO_PATH"
    exit 1
fi

echo ""
echo "🔗 $PROJECT_NAME ↔ $(basename "$REPO_PATH") 연결 중..."
echo ""

# ── .claude/commands/ 생성 ────────────────────────────────────

CLAUDE_DIR="$REPO_PATH/.claude/commands"
mkdir -p "$CLAUDE_DIR"

# ── /wiki-start ───────────────────────────────────────────────
cat > "$CLAUDE_DIR/wiki-start.md" << EOF
세션 시작 루틴을 수행하라:

1. $WIKI_ROOT/projects/$PROJECT_NAME/status.md를 읽어서 현재 상태를 파악하라.
2. $WIKI_ROOT/projects/$PROJECT_NAME/sessions/ 에서 최근 세션 로그 3개를 읽어서 맥락을 복원하라.
3. $WIKI_ROOT/projects/$PROJECT_NAME/issues/ 에서 미해결 이슈(resolved: false)가 있는지 확인하라.
4. 현재 작업에 관련된 $WIKI_ROOT/knowledge/ 페이지가 있으면 참고하라.
5. 현재 상태, 최근 작업 요약, 추천 다음 작업을 보고하라.
EOF
echo "  ✅ /wiki-start"

# ── /wiki-end ─────────────────────────────────────────────────
cat > "$CLAUDE_DIR/wiki-end.md" << EOF
세션 종료 루틴을 수행하라:

1. 오늘 작업 내용을 $WIKI_ROOT/projects/$PROJECT_NAME/sessions/ 에 세션 로그로 기록하라.
   - 파일명: YYYY-MM-DD-주제.md (주제는 핵심 작업을 kebab-case로)
   - $WIKI_ROOT/projects/$PROJECT_NAME/sessions/000-template.md 형식을 따르라.

2. $WIKI_ROOT/projects/$PROJECT_NAME/status.md를 갱신하라.
   - 완료된 작업을 체크하고 다음 할 일을 업데이트하라.

3. 새로운 기술 의사결정이 있었으면:
   - $WIKI_ROOT/projects/$PROJECT_NAME/decisions/ 에 ADR을 작성하라.
   - 000-template.md 형식, 번호는 기존 최대값 + 1.

4. 해결한 문제가 있으면:
   - $WIKI_ROOT/projects/$PROJECT_NAME/issues/ 에 기록하라.
   - 000-template.md 형식.

5. 범용적 지식 (다른 프로젝트에서도 쓸 수 있는 것)이 있으면:
   - 도구/기술 → $WIKI_ROOT/knowledge/tools/
   - 패턴 → $WIKI_ROOT/knowledge/patterns/
   - 트러블슈팅 → $WIKI_ROOT/knowledge/troubleshooting/
   - 프롬프팅 팁 → $WIKI_ROOT/knowledge/prompting/

6. $WIKI_ROOT/_meta/log.md 맨 아래에 항목 추가:
   ## [YYYY-MM-DD] session | $PROJECT_NAME — (핵심 주제)

7. 새 페이지를 만들었으면 $WIKI_ROOT/_meta/index.md를 갱신하라.
EOF
echo "  ✅ /wiki-end"

# ── /wiki-decision ────────────────────────────────────────────
cat > "$CLAUDE_DIR/wiki-decision.md" << EOF
방금 논의한 기술 의사결정을 ADR로 기록하라:

1. $WIKI_ROOT/projects/$PROJECT_NAME/decisions/ 의 기존 파일을 확인해서 다음 번호를 결정하라.
2. ADR을 생성하라.
   - 형식: $WIKI_ROOT/projects/$PROJECT_NAME/decisions/000-template.md 참조
   - 맥락, 선택지, 결정, 근거, 결과를 모두 채워라.
3. $WIKI_ROOT/projects/$PROJECT_NAME/overview.md 의 "주요 의사결정" 섹션에 링크를 추가하라.
4. $WIKI_ROOT/projects/$PROJECT_NAME/architecture.md 의 "관련 의사결정"에도 링크를 추가하라.
5. 관련 기술의 $WIKI_ROOT/knowledge/tools/ 페이지가 있으면 갱신하라. 없으면 새로 만들라.
6. $WIKI_ROOT/_meta/log.md에 기록하라:
   ## [YYYY-MM-DD] decision | $PROJECT_NAME — ADR-NNN 제목
EOF
echo "  ✅ /wiki-decision"

# ── /wiki-issue ───────────────────────────────────────────────
cat > "$CLAUDE_DIR/wiki-issue.md" << EOF
방금 해결한 문제를 위키에 기록하라:

1. $WIKI_ROOT/projects/$PROJECT_NAME/issues/ 에 문제 해결 기록을 생성하라.
   - 형식: $WIKI_ROOT/projects/$PROJECT_NAME/issues/000-template.md 참조
   - 증상, 시도한 것들, 근본 원인, 해결 방법, 예방책을 모두 채워라.

2. 이 문제가 다른 프로젝트에서도 재발할 수 있는 범용적 문제라면:
   - $WIKI_ROOT/knowledge/troubleshooting/ 에 일반화된 버전을 작성하라.
   - 프로젝트 이슈 페이지에서 knowledge 페이지로 [[링크]]를 걸라.

3. 관련 도구의 $WIKI_ROOT/knowledge/tools/ 페이지에 "주의사항" 섹션을 갱신하라.

4. $WIKI_ROOT/_meta/log.md에 기록하라:
   ## [YYYY-MM-DD] issue | $PROJECT_NAME — 문제 요약
EOF
echo "  ✅ /wiki-issue"

# ── /wiki-lint ────────────────────────────────────────────────
cat > "$CLAUDE_DIR/wiki-lint.md" << EOF
이 프로젝트의 위키 건강 점검을 수행하라:

1. $WIKI_ROOT/projects/$PROJECT_NAME/ 의 모든 md 파일을 읽어라.

2. 다음을 점검하라:
   - 프론트매터가 비어있거나 규약에 맞지 않는 페이지
   - 깨진 내부 링크 ([[...]]가 가리키는 페이지가 없는 경우)
   - status.md가 실제 진행 상황과 맞는지
   - sessions/ 로그가 최근 작업을 반영하는지
   - issues/ 에서 resolved: false인데 실제로는 해결된 건 없는지

3. $WIKI_ROOT/knowledge/ 관련 페이지도 점검하라:
   - 이 프로젝트 스택의 도구 knowledge 페이지가 있는지
   - 있다면 최신 정보를 반영하는지

4. 발견 사항을 요약하고 수정 제안을 하라.
5. 동의하면 일괄 적용하라.

6. $WIKI_ROOT/_meta/log.md에 기록하라:
   ## [YYYY-MM-DD] lint | $PROJECT_NAME — 점검 결과 요약
EOF
echo "  ✅ /wiki-lint"

# ── CLAUDE.md Wiki Integration ────────────────────────────────

CLAUDEMD="$REPO_PATH/CLAUDE.md"
WIKI_MARKER="# Wiki Integration"

add_wiki_section() {
    cat << EOF

$WIKI_MARKER

이 프로젝트의 지식은 Obsidian 위키에서 관리된다.

- **Wiki 경로:** $WIKI_ROOT
- **프로젝트 위키:** $WIKI_ROOT/projects/$PROJECT_NAME
- **위키 인덱스:** $WIKI_ROOT/_meta/index.md
- **횡단 지식:** $WIKI_ROOT/knowledge/

## 위키 커맨드

| 커맨드 | 용도 |
|--------|------|
| \`/wiki-start\` | 세션 시작 — 상태 파악, 맥락 복원 |
| \`/wiki-end\` | 세션 종료 — 로그 작성, 상태 갱신 |
| \`/wiki-decision\` | 의사결정 ADR 기록 |
| \`/wiki-issue\` | 문제 해결 기록 |
| \`/wiki-lint\` | 위키 건강 점검 |

## 자동 수행 규칙

- 아키텍처 변경 시 → overview.md, architecture.md 갱신
- 새 기술 도입 시 → knowledge/tools/ 페이지 확인 및 갱신
- 버그 해결 시 → 범용적이면 knowledge/troubleshooting/에도 기록
EOF
}

if [ -f "$CLAUDEMD" ]; then
    if grep -q "$WIKI_MARKER" "$CLAUDEMD"; then
        echo "  ⏭️  CLAUDE.md에 이미 Wiki Integration 있음"
    else
        add_wiki_section >> "$CLAUDEMD"
        echo "  ✅ CLAUDE.md에 Wiki Integration 추가"
    fi
else
    {
        echo "# $PROJECT_NAME"
        add_wiki_section
    } > "$CLAUDEMD"
    echo "  ✅ CLAUDE.md 생성"
fi

# ── 완료 ──────────────────────────────────────────────────────

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✅ 연결 완료: $PROJECT_NAME ↔ $(basename "$REPO_PATH")"
echo "══════════════════════════════════════════════════"
echo ""
echo "  Claude Code에서 사용:"
echo "    /wiki-start      세션 시작"
echo "    /wiki-end        세션 종료"
echo "    /wiki-decision   의사결정 기록"
echo "    /wiki-issue      문제 해결 기록"
echo "    /wiki-lint       위키 점검"
echo ""
