---
type: session-log
project: dna-sql-agent-web
date: 2026-05-14
duration: ~1h
focus: "CI/CD 포트 설정 수정 & 시스템 선택 팝업 디버깅"
tools-used: [claude-code]
outcome: success
---

# 2026-05-14 — docker network host 적용 & 시스템 선택 팝업 미출력 원인 파악

## 목표

1. GitHub Actions 배포 시 포트 포워딩(`-p 28001:3000`) 대신 `--network host`로 변경
2. 채팅 추가 시 시스템 선택 팝업이 안 뜨는 원인 파악

## 수행한 작업

1. `.github/workflows/main.yml` `docker run` 옵션 수정
   - `-p 28001:3000` → `--network host`
   - 컨테이너가 호스트 네트워크를 직접 사용, Dockerfile의 `EXPOSE 28001` / `ENV PORT=28001`과 일치
2. 시스템 선택 팝업 미출력 원인 코드 추적
   - `page.tsx` → `handleNewConversation` → `availableSystems` 상태 흐름
   - `use-conversations.ts` → `loadMySystems` → `getMySystems()` 호출 경로 확인
   - `/api/v1/auth/me/systems` 엔드포인트가 개발자 도구 Network 탭에 기록이 없음 확인

## 핵심 결정

- **`--network host` 채택:** 포트 포워딩 없이 컨테이너가 호스트 네트워크를 직접 사용. Dockerfile의 PORT=28001과 맞춤.

## 배운 것

- 팝업 표시 조건: `availableSystems` 중 `status === 'active'`인 시스템이 **2개 이상**일 때만 팝업. 1개이면 바로 그 시스템으로 생성, 0개이면 system 없이 생성.
- 실제 원인: 시스템이 1개였음. 팝업이 안 뜨는 게 의도된 동작이었고, 사용자가 2개라고 착각한 것.

## 문제 & 해결

- **문제:** 채팅 추가 버튼 클릭 시 시스템 선택 팝업 미출력
- **원인:** active 시스템이 1개 → `handleNewConversation`이 팝업 없이 바로 대화 생성 (설계된 동작)
- **해결:** 실제 시스템 수가 1개임을 확인, 버그 아님

## 다음 할 일

- [ ] 채팅 목록 제목 정책 수립 및 반영
- [ ] 채팅 목록에서 "No message" 표시 원인 확인 및 처리
- [ ] main.yml 커밋/푸시 (세션 중 미완료)

## 효과적이었던 프롬프트

```
개발자 도구에서 api 기록이 없다고 그거
```
→ 네트워크 탭 확인을 기준으로 디버깅 범위를 빠르게 좁혀줬음
