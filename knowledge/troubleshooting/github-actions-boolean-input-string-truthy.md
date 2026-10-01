---
type: troubleshooting
scope: general
date: 2026-08-06
tags: [github-actions, ci, workflow_dispatch, gotcha]
---

# GitHub Actions — `type: boolean` 입력은 표현식에서 문자열이라 `"false"` 도 참

## 한 줄

`workflow_dispatch` 의 `type: boolean` 입력을 `if: ${{ inputs.x }}` 로 쓰면,
꺼도(`false`) **항상 참**이 된다. 표현식 컨텍스트에서 문자열 `"false"` 로 들어오고,
비어 있지 않은 문자열은 참이기 때문이다.

## 증상

체크박스를 끄고 실행했는데 조건부 스텝이 그대로 실행된다. 반대로 `!` 를 붙인
스텝은 켜도 꺼도 항상 건너뛴다.

## 왜 이렇게 되나

```yaml
on:
  workflow_dispatch:
    inputs:
      rebuild:
        type: boolean
        default: false
```

| 표현 | `rebuild = false` 일 때 | 결과 |
|---|---|---|
| `${{ inputs.rebuild }}` | `"false"` (비어 있지 않은 문자열) | **참** |
| `${{ !inputs.rebuild }}` | `!"false"` | **거짓** |

즉 긍정 조건은 항상 실행되고, 부정 조건은 항상 건너뛴다.

## 해결

`github.event.inputs.*` 는 문서상 **항상 문자열**이다. 이쪽으로 명시 비교한다.

```yaml
    if: ${{ github.event.inputs.rebuild == 'true' }}      # 켰을 때만
    if: ${{ github.event.inputs.rebuild != 'true' }}      # 껐을 때만
```

셸 안에서 쓰는 경우는 어차피 문자열 비교라 원래 안전하다.

```bash
if [ "${{ inputs.rebuild }}" = "true" ]; then ... ; fi
```

`inputs.x == true`(불리언 비교)는 컨텍스트에 따라 타입이 달라질 수 있어 권하지 않는다.
문자열로 통일하는 편이 예측 가능하다.

## 왜 놓치기 쉬운가

- **켠 쪽만 테스트하면 정상으로 보인다.** 실행돼야 할 것이 실행되기 때문이다.
  끈 쪽을 돌려야 드러난다
- **부정 조건의 피해가 더 크고 조용하다.** 스텝이 실행되지 않으면 에러가 나지 않고
  그냥 `skipped` 다. 그 스텝이 하던 준비 작업(태깅·파일 생성 등)이 사라진 채
  **한참 뒤 다른 스텝에서** 엉뚱한 에러로 터진다
- 로그의 에러 메시지만 보면 2차 원인으로 빠진다. **스텝별 skipped/success 목록을
  먼저 볼 것**

## 예방책

조건부 스텝을 추가하면 **양쪽 분기를 각각 한 번씩** 돌려 본다. boolean 입력이
있는 워크플로에서는 이것이 사실상 유일한 검증 수단이다.

## 관련 페이지

- [[projects/dna-sql-agent/issues/github-actions-boolean-input-always-truthy]]
