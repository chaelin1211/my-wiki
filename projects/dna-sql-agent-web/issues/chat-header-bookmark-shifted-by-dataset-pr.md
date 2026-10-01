---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-10-01
resolved: true
root-cause: "PR #96 에서 헤더 버튼을 ml-auto 래퍼로 묶으며 북마크 버튼만 래퍼 밖에 남고 ml-auto 가 제거됨"
related: [chat-header]
tags: [layout, regression]
---

# 채팅 헤더 북마크 버튼이 제목 옆으로 밀림

## 증상

채팅 상단 헤더의 북마크 버튼이 오른쪽 버튼 영역이 아니라 제목 바로 옆에 표시.

## 근본 원인

PR #96(개인 데이터셋 업로드, f7bc6a3)이 데이터셋 관리 버튼을 넣으며 보고서·데이터셋 버튼을 `ml-auto` 래퍼로 묶었는데, 북마크 `<span>` 의 `ml-auto` 를 빼고 래퍼 **앞**에 남겨 둠. 커밋·PR 본문에 위치 변경 언급 없음 → 사이드이펙트.

## 해결 방법

북마크 블록을 `ml-auto` 래퍼의 첫 자식으로 이동(7fa2ab4). PR 웹 #97.
