---
type: troubleshooting
project: dna-sql-agent
date: 2026-11-03
resolved: true
root-cause: "한 답변이 여러 행으로 저장되는데 화면은 첫 행 ID를 보내고 보고서는 id <= 그 ID까지만 읽음"
related: [search-target-merged-message-row-id]
tags: [report, pdf, message-id]
---

# 결과 표가 있는 대화에서 PDF 보고서 404, 마지막 질문 결과 누락

## 증상

```
POST /api/v1/report/generate 404 — No analysis steps found in this conversation.
```

요청은 `{"conversation_id": "conv_284e7578", "message_id": "2076434"}`. 결과 표가 있는 대화인데 404, 여러 질문 대화는 마지막 질문 결과만 빠짐.

## 원인

한 답변은 진행 상태(2076434)·결과 표(2076436)·최종 설명(2076438) 행으로 저장된다. 화면은 대화를 다시 불러올 때 행을 합치며 첫 행 ID를 쓰고, 스트림 종료 응답도 `_save_components`가 첫 행 ID로 덮어써 돌려준다. 보고서는 `id <= message_id`까지만 읽어 결과 표가 빠진다. 메시지별 슬라이드는 묶음의 `message_id`(마지막 행)와 `==` 비교라 범위를 고치면 어긋난다.

## 해결

- `fetch_report_data`: 받은 ID 다음 사용자 메시지 직전까지(없으면 끝까지) 읽기, 묶음마다 행 ID 목록(`message_ids`) 기록.
- `select_step_for_message`: 받은 ID가 행 ID 목록에 있으면 그 묶음.
- 스트림 종료 ID를 마지막 행으로 바꾸는 방법은 새로 고침 화면(첫 행)과 피드백 ID가 어긋나 채택하지 않음. 화면 수정 없음.

## 교훈

여러 행을 하나로 합쳐 보여 주는 화면의 대표 ID는 범위의 시작일 뿐이다. 그 ID로 "까지"를 계산하는 쪽은 묶음 끝을 직접 찾아야 한다. 같은 계열: [[issues/search-target-merged-message-row-id]], [[knowledge/troubleshooting/merged-rows-single-id-loses-child-location]]
