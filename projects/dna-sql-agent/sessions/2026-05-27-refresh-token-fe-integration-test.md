---
type: session-log
project: dna-sql-agent
date: 2026-05-27
duration: ~2h
focus: "refresh token 프론트엔드 연동 검토·테스트 및 PR 생성"
tools-used: [claude-code]
outcome: success
---

# 2026-05-27 — Refresh Token 프론트엔드 연동 검토·테스트

## 목표

백엔드에 구현된 refresh token을 프론트엔드와 연동하고, 정상 동작을 확인한 뒤 PR을 생성한다.

## 수행한 작업

1. `docs/refresh-token-frontend-guide.md` 읽고 웹 팀에 수정사항 요약 전달
2. 웹 팀 실행계획 검토 — 수정 필요 사항 2개 도출
   - `fetchWithAuth()`가 refreshToken에 접근하는 방법 명시 없음
   - `refreshTokenApi()` · `logoutApi()` 자체는 fetchWithAuth() 쓰면 안 됨 (무한루프)
   - 큐 실패(catch) 시 대기 요청 reject 처리 누락
3. 테스트 방법 설명 (JWT_EXPIRE_MINUTES=1, 2회 연속 refresh 검증법)
4. `.env` `JWT_EXPIRE_MINUTES` 30 → 1 임시 변경
5. `docs/chat-history-design.md` 업데이트 — 신규 엔드포인트, JWT 설정 섹션 반영
6. ADR-004 작성 — refresh token 도입 의사결정 기록
7. `overview.md` 의사결정 테이블 갱신 (ADR 001~004)
8. 웹 연동 완료 후 테스트 진행
   - 로그인 → access_token + refresh_token 발급 확인
   - 1분 후 401 → auto refresh → 재시도 성공 확인
9. 버그 진단: refresh 후 바로 로그인 페이지로 이동
   - **원인:** rotation으로 발급된 새 refresh_token을 저장하지 않아, 다음 401 시 무효 토큰으로 refresh 시도 → 실패 → 로그인 이동
   - **수정:** 웹 팀이 `saveRefreshToken(tokens.refresh_token)` 추가
10. 2회 연속 refresh 테스트 통과 확인
11. `.env` JWT_EXPIRE_MINUTES 1 → 30 원복
12. PR #33 생성 (`feat/auth` → `main`)

## 핵심 결정

- **refresh token rotation:** 매 refresh마다 새 refresh_token 발급. 프론트는 access_token + refresh_token 둘 다 교체해서 저장해야 함.
  → ADR: [[decisions/004-refresh-token-auth]]

## 배운 것

- Refresh token rotation 구현 시 가장 흔한 버그: access_token만 저장하고 refresh_token 교체를 빠뜨리는 것
- 이를 검증하는 가장 확실한 테스트: 짧은 만료 시간으로 **2회 연속 refresh** 통과 여부 확인

## 문제 & 해결

- **문제:** 첫 번째 refresh 성공 후 다음 API 호출 시 바로 로그인 페이지로 이동
- **원인:** rotation으로 새 refresh_token이 발급됐는데 프론트가 저장하지 않아 이전(무효) 토큰으로 재시도
- **해결:** `saveRefreshToken(tokens.refresh_token)` 추가
  → 이슈: [[issues/refresh-token-rotation-not-saved]]

## 다음 할 일

- [ ] PR #33 리뷰 및 머지
- [ ] SQL Guard: group 별 테이블 접근 제한 DB 연동
