---
type: decision-record
project: dna-sql-agent
date: 2026-06-10
status: accepted
tags: [sql-guard, llm, agent-loop, security]
---

# ADR-011: 가드레일 차단 시 LLM 재시도 방지 전략

## 맥락

SQL 가드레일이 차단 결과를 반환해도 에이전트 루프는 계속 돌아간다. LLM은 `"SQL validation failed: ..."` 에러 메시지를 받고 쿼리를 수정해 재시도한다. 3회 정도 후 차단 조건을 우회한 쿼리를 만들어내는 문제가 발생.

## 선택지

### 옵션 A: 에이전트 루프 abort
- `ToolResult.metadata["abort"] = True`를 심고, `agent.py` 루프에서 해당 플래그를 감지해 `break`
- **장점:** 완전히 재시도 불가
- **단점:** LLM이 차단 사실을 요약/안내하는 최종 응답을 생성하지 못함 → 사용자에게 아무 설명 없이 멈춤 (UX 깨짐)

### 옵션 B: result_for_llm에 재시도 금지 지시 포함 (선택)
- `result_for_llm`에 `[보안 정책 차단 - 재시도 금지]\n{사유}\n\n절대로 쿼리를 수정하거나 재시도하지 마십시오. 사용자에게 안내하고 대화를 종료하십시오.` 포함
- **장점:** LLM이 차단 안내 응답을 생성 가능, UX 유지
- **단점:** LLM 지시 따르기에 의존 — 이론적으로 무시 가능성 있음

### 옵션 C: 시스템 프롬프트에 가드레일 정책 명시
- **장점:** 모든 요청에 적용
- **단점:** 시스템 프롬프트가 길어지고, 특정 차단 케이스에 대한 세밀한 지시 불가

## 결정

**옵션 B를 선택한다.** rule별 한국어 메시지 + 재시도 금지 명령을 `result_for_llm`에 포함. 장기적으로 옵션 A+B 조합(abort + 루프 외부에서 별도 LLM 호출로 안내 생성)을 검토할 수 있으나 현재는 B로 충분.

## 근거

- 옵션 A는 UX를 깨트림. 사용자는 "왜 갑자기 응답이 없지?"라는 경험
- LLM은 명확한 한국어 "재시도 금지" + "사용자에게 안내하라" 지시를 일반적으로 잘 따름
- rule별 맥락 메시지(`blocked_table_access`, `write_in_read_only_mode` 등)가 있어 LLM이 적절한 안내를 생성하기 쉬움

## 결과

- `guardrail.py`에 `_BLOCK_MESSAGES` 딕셔너리로 rule별 메시지 관리
- `validated_run_sql._make_error_result(guardrail_block=True)` 경로에서 래핑
- 추후 LLM 모델 교체 시 지시 준수율 재검증 필요
