---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-06
resolved: true
root-cause: "workflow_dispatch 의 type: boolean 입력이 표현식에서 문자열로 들어와, if: ${{ inputs.x }} 가 \"false\" 에도 참이 됨"
related: [github-actions, workflow_dispatch, dna-sql-agent-deploy]
tags: [ci, github-actions, gotcha]
---

# 워크플로 boolean 입력을 껐는데도 스텝이 실행됨

## 증상

`dna-sql-agent-deploy` 의 "배포 패키지 생성" 워크플로에서 **"이미지를 소스에서
새로 빌드"를 끄고** 실행했는데, 소스 체크아웃 스텝이 실행되며 실패했다.

```
##[error]Input required and not supplied: token
```

스텝별 결과:

```
success   배포 저장소
failure   백엔드 소스        ← rebuild 를 껐는데 실행됨
skipped   웹 소스
skipped   실행 환경 확인
skipped   묶을 이미지 확인
skipped   패키지 생성
```

## 환경

- **CI:** GitHub Actions, self-hosted runner (`[self-hosted, mobigen]`)
- **트리거:** `workflow_dispatch`
- **관련 파일:** `.github/workflows/package.yml`
- **재현 조건:** `type: boolean` 입력을 `if: ${{ inputs.<name> }}` 로 분기

## 시도한 것들

1. ❌ 시크릿(`SOURCE_REPOS_TOKEN`) 미등록이 원인이라고 봄 — 그건 **2차 원인**이다.
   애초에 그 스텝이 실행되지 말았어야 했다
2. ✅ 스텝별 실행 여부를 확인 → 꺼져 있는데 실행된 것이 진짜 문제임을 확인

## 근본 원인

`workflow_dispatch` 의 입력은 `type: boolean` 으로 선언해도 **표현식 컨텍스트에서
문자열로 들어온다.** GitHub Actions 표현식에서 비어 있지 않은 문자열은 참이므로
`"false"` 도 참이다.

```yaml
inputs:
  rebuild:
    type: boolean
    default: false
...
  - name: 백엔드 소스
    if: ${{ inputs.rebuild }}     # "false" → 참 → 항상 실행
```

**더 나쁜 것은 부정형이다.** `!inputs.rebuild` 는 `!"false"` → 거짓이므로
**항상 건너뛴다.**

| 조건 | 의도 | 실제 |
|---|---|---|
| `${{ inputs.rebuild }}` | rebuild 일 때만 | **항상 실행** |
| `${{ !inputs.rebuild }}` | rebuild 아닐 때만 | **항상 건너뜀** |

이 워크플로에서는 항상 건너뛴 스텝(`묶을 이미지 확인`)이 `docker tag latest → <버전>`
을 하고 있었다. 그래서 체크아웃 문제를 고쳐도 `package.sh` 가
`이미지가 없습니다: dna-sql-agent:1.0` 으로 죽는다.
**즉 어떤 입력 조합으로도 성공할 수 없는 상태였다.**

## 해결 방법

`github.event.inputs.*` 는 문서상 항상 문자열이므로 이쪽으로 명시 비교한다.

```yaml
  - name: 백엔드 소스
    if: ${{ github.event.inputs.rebuild == 'true' }}

  - name: 묶을 이미지 확인
    if: ${{ github.event.inputs.rebuild != 'true' }}
```

셸 안에서 쓰는 경우는 원래부터 문자열 비교라 문제가 없다.

```bash
if [ "${{ inputs.rebuild }}" != "true" ]; then
  args="$args --no-build"
fi
```

커밋: `86e96ff` (dna-sql-agent-deploy)

## 예방책

- **`if:` 에서 boolean 입력을 맨몸으로 쓰지 않는다.** 항상 `== 'true'` 로 비교한다
- **부정 조건을 특히 조심한다.** `!input` 은 조용히 "항상 거짓"이 되어,
  실행되지 않은 스텝이 하던 일(여기서는 태깅)까지 함께 사라진다
- **조건부 스텝을 추가하면 양쪽 분기를 모두 한 번씩 돌려 본다.** 이번에는 끈 쪽만
  돌려서 발견됐는데, 켠 쪽만 돌렸으면 정상으로 보였을 것이다
- 실패 시 로그의 **스텝별 skipped/success 목록**을 먼저 본다. 에러 메시지
  (`token` 미제공)만 보면 2차 원인으로 빠진다

## 관련 페이지

- [[knowledge/troubleshooting/github-actions-boolean-input-string-truthy]]
