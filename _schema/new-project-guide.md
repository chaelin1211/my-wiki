---
type: guide
created: 2026-05-18
updated: 2026-05-18
---

# 새 프로젝트 생성 가이드

## 1. 스크립트 실행

```bash
cd "LLM WIKI GUIDE"
./new-project.sh {project-name}
```

프롬프트에 따라 입력한다:
- **프로젝트 이름**: kebab-case (예: `dna-sql-agent`, `project-nova`)
- **한 줄 목표**: 프로젝트가 풀려는 문제
- **기술 스택**: 쉼표 구분 (예: `nextjs,fastapi,postgresql`)
- **GitHub repo URL**: 없으면 엔터 (나중에 `link-repo.sh`로 연결 가능)
- **repo 로컬 경로**: 없으면 엔터

스크립트가 자동으로 생성하는 파일:

```
projects/{project-name}/
├── overview.md
├── architecture.md
├── status.md
├── decisions/000-template.md
├── meetings/_template.md    ← 생성일 기준 날짜·요일 자동 삽입
│   └── old/
├── sessions/000-template.md
├── issues/000-template.md
└── raw/README.md
```

## 2. 각 파일 역할

### overview.md
프로젝트의 **진입점**. 목표·스택·주요 의사결정 링크를 한 곳에 모은다.
→ 템플릿: `_schema/templates/project-overview.md`

### architecture.md
시스템 구조, 데이터 흐름, 외부 의존성을 기록한다.
세부 기술 결정은 `decisions/`에 ADR로 분리한다.

### status.md
현재 진행 상황. **wiki-weekly-sync** 스킬이 주간보고를 읽어 자동 갱신한다.

```yaml
## 완료된 것   ← DONE
## 진행 중     ← ING
## 다음 할 일  ← TODO
## 블로커
## 메모        ← 회의록 링크 자동 추가됨
```

### decisions/ (ADR)
파일명: `NNN-제목.md` (예: `001-llm-선택.md`)
→ 템플릿: `decisions/000-template.md`

결정 하나당 파일 하나. 변경 시 `superseded-by` 필드에 새 ADR 파일명을 기입하고 `status: superseded`로 변경한다.

### meetings/
파일명: `YYYY-MM-DD 회의 제목.md`
제목(H1): `# YYYY-MM-DD (요일) — 회의 제목`

**wiki-meeting-sync** 스킬이 오늘 날짜 파일을 자동으로 감지해 `status.md`에 반영한다.

```yaml
---
type: meeting
project: {project-name}
date: YYYY-MM-DD
attendees: []
---
```

섹션 구성:

| 섹션 | status.md 반영 대상 |
|------|-------------------|
| `## 결정사항` | 완료된 것 |
| `## 액션아이템` | 다음 할 일 |
| `## 진행 중` | 진행 중 |
| `## 안건` | 자동 추출 후 확인 요청 |

`meetings/old/` — 정리 전 날 것의 메모를 임시 보관. 정리 완료 후 삭제해도 무방.

### sessions/
파일명: `YYYY-MM-DD-주제.md`
Claude Code 작업 세션 단위로 기록. 무엇을 왜 했는지, 배운 것, 다음 할 일.
→ 템플릿: `sessions/000-template.md`

### issues/
파일명: `문제-요약.md`
재현 조건·원인·해결 방법을 기록한다. 해결되면 `resolved: true`로 변경.
→ 템플릿: `issues/000-template.md`

### raw/
**LLM이 수정하지 않는다.** 원본 자료(요구사항 문서, 스크린샷, 외부 참고 자료)를 보관.

## 3. 스킬 연동

| 스킬 | 트리거 | 동작 |
|------|--------|------|
| `/wiki-weekly-sync` | 수동 | 주간보고 → 각 프로젝트 status.md 갱신 |
| `/wiki-weekly-rollover` | 매주 월요일 | 직전 주 ING·TODO → 이번 주 주간보고 이관 |
| `/wiki-meeting-sync` | 수동 | 오늘 날짜 회의록 → status.md 갱신 |

## 4. 체크리스트

새 프로젝트 생성 후 확인:

- [ ] `./new-project.sh` 실행 완료
- [ ] `overview.md` 목표·스택 채움
- [ ] `architecture.md` 시스템 개요 초안 작성
- [ ] `status.md` 초기 TODO 작성
- [ ] `_schema/CLAUDE.md` 디렉토리 구조와 일치하는지 확인
- [ ] Git 커밋 & 푸시
