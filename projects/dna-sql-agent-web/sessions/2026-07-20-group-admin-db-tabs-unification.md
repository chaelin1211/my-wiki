---
type: session-log
project: dna-sql-agent-web
date: 2026-07-20
duration:
focus: "그룹 관리자 DB 관리(연결·시스템) 화면 — admin 컴포넌트 공용화"
tools-used: [claude-code]
outcome: success
---

# 2026-07-20 — 그룹 관리자 DB 관리 화면: admin과 공용 컴포넌트로 통합

## 목표

7/16에 만든 `/admin/group-manage/database`의 연결·시스템 탭이 `/admin/database`
(시스템 관리자용)와 컬럼·버튼 문구가 다르고, 전체 목록을 한 번에 받아 클라이언트
에서 페이지만 잘라내는 가짜 페이지네이션을 쓰고 있었음. 이걸 admin과 화면·동작이
동일하도록 공용 컴포넌트로 리팩터링. 백엔드 작업(서버 페이지네이션 API, 권한 감사,
커넥션 정책 재조정)은
[[projects/dna-sql-agent/sessions/2026-07-20-group-admin-db-tabs-unification|dna-sql-agent 세션 로그]] 참고.

## 수행한 작업

1. **연결 관리 탭 공용화** — `ConnectionList`를 데이터/액션을 props로 받는 구조로
   리팩터링(내부에서 직접 훅 호출하던 걸 제거), `useGroupDbConnections` 훅 신설
   — `useDbConnections`와 동일한 반환 모양으로 group-admin API의 신규 서버
   페이지네이션 사용
2. **시스템 관리 탭 공용화** — admin `SystemList`의 테이블 부분을 제네릭
   `SystemTable`(`T extends SystemListItem`)로 분리, `useGroupDbSystems` 훅 신설.
   그룹 쪽에만 있던 인라인 "지식화 트리거" 버튼은 이미 있는 지식화 탭과 중복이라
   제거
3. **정책 변화에 맞춘 UI 조정 (여러 차례)**
   - 1차: 공유 커넥션 편집 제한 → 자물쇠 아이콘 + disabled 버튼으로 표현
   - 2차(정책 변경): 그 제한을 제거하고 삭제 확인창에 "다른 그룹과 공유되고
     있습니다" 빨간 경고 문구로 대체 (연결 탭에서 먼저 하고, 시스템 탭에도 같은
     패턴 적용)
   - 3차(정책 변경): 커넥션 쪽이 완전 개방으로 바뀌면서 저 경고 문구 자체가
     의미 없어져 제거. `ConnectionRow`(exclusively_owned 얹은 타입)도 다시
     plain `Connection`으로 되돌림
   - 새 시스템 등록 다이얼로그(`group-system-dialog.tsx`)의 커넥션 선택 목록도
     "단독 소유만" 필터 → 전체 표시로 변경, "단독 소유 커넥션 없어서 시스템 생성
     불가" 버튼 비활성화 로직 제거
4. 지식화/SQL예제 탭은 이미 무거운 admin 컴포넌트(`VectorizationPanel` 4267줄,
   `SqlExamplesPanel` 860줄)를 `api` prop으로 주입받는 얇은 래퍼(42줄/34줄) 구조로
   돼 있어서 손댈 게 없었음 — 이 세션에서 "더 줄일 수 있나" 검토했지만 이미 정석
5. 커밋 4건 (연결 탭 공용화 / 시스템 탭 공용화 / 연결 삭제 경고+시스템명 표시
   보완 / 커넥션 전면개방에 맞춘 UI 정리)

## 핵심 결정

- **결정 1:** admin/group-manage 두 페이지를 아예 하나의 라우트로 합치는 안은
  검토만 하고 보류 — React Hook 규칙상 역할별로 다른 훅을 조건부 호출할 수 없어
  두 훅을 항상 호출하고 `enabled` 플래그로 fetch만 막는 패턴이 필요한데, 이게
  페이지 가드·사이드바 링크 정리까지 포함하면 오늘 스코프보다 훨씬 큰 별도 작업
  이라 판단
- **결정 2:** admin `useDbConnections`/group `useGroupDbConnections` 같은 중복
  훅 쌍을 `hooks/use-sql-examples.ts`의 `useSqlExamples(systems, api = defaultApi)`
  패턴(팩토리 대신 훅이 `api` 파라미터를 받고 기본값은 admin API)으로 통일하자는
  방향까지는 합의했으나 **미착수** — 다음 세션 과제

## 배운 것

- `npx tsc`가 로컬 tsc 해석에 실패하면(네트워크 이슈 등) "This is not the tsc
  command you are looking for" 안내를 출력하고 **exit 0으로 조용히 끝나서** 마치
  "에러 0건"인 것처럼 보인다 — `./node_modules/.bin/tsc`로 직접 호출해서 실제
  결과인지 항상 재확인할 것. 이번 세션에서 두 번 이 함정에 빠질 뻔했다.
- 컴포넌트를 admin/group 공용으로 뺄 때, "완전히 같은 컴포넌트"와 "테이블만
  공유하고 헤더/다이얼로그는 각자"를 구분하는 기준은 다이얼로그 크기 차이였다 —
  `ConnectionDialog`는 두 쪽 다 크기가 비슷하고 콜백 기반이라 그대로 공유했지만,
  `SystemDialog`(770줄)와 `GroupSystemDialog`(156줄)는 크기 차이가 너무 커서
  테이블(`SystemTable`)만 추출하고 다이얼로그는 그대로 각자 뒀다.

## 문제 & 해결

_(이번 세션 프론트엔드 자체 버그는 없음 — 백엔드 500 에러는
[[projects/dna-sql-agent/sessions/2026-07-20-group-admin-db-tabs-unification|백엔드 세션 로그]] 참고)_

## 다음 할 일

- [ ] `useDbConnections`/`useGroupDbConnections`, `useDbSystems`/`useGroupDbSystems`를
      `useSqlExamples` 패턴(단일 훅 + `api` 파라미터)으로 통일 — 오늘 합의만 하고
      미착수
- [ ] admin/group-manage 페이지 통합 여부 — 결정 2 참고, 별도 세션에서 라우팅+
      레이아웃+훅 enable 패턴까지 묶어서 검토
- [ ] PR 생성 (이번 세션 4커밋)

## 효과적이었던 프롬프트

```
아 근데 지금 생각하니까 그냥 관리자 페이지 내에서 props로 메뉴 viewing 조절하고
데이터 불러오는 것도 api 분기 타고 (서버에서 권한 하드하게 방어) 하는게 더 품이
덜 들었을 거 같은데 흠
```
