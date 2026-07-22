---
type: session-log
project: dna-sql-agent
date: 2026-07-20
duration:
focus: "그룹 관리자 DB 관리(연결·시스템) API — admin과 공용화, 권한 점검, 커넥션 정책 재조정"
tools-used: [claude-code]
outcome: success
---

# 2026-07-20 — 그룹 관리자 DB 관리 API: 서버 페이지네이션, 권한 감사, 커넥션 정책 개방

## 목표

7/16에 만든 그룹 관리자 데이터베이스 관리 화면(연결/시스템 탭)이 시스템 관리자
화면과 컬럼·문구가 다르고, 목록을 전체로 받아 클라이언트에서 자르는 가짜
페이지네이션을 쓰고 있던 것을 admin과 동일한 서버 페이지네이션 + 공용 컴포넌트로
정리. 그 과정에서 권한 체크 전수 감사를 하다 실제 구멍을 하나 발견·수정했고,
이어서 그룹 관리자의 커넥션 접근 범위 정책을 두 번 조정했다 (프론트엔드 작업은
[[projects/dna-sql-agent-web/sessions/2026-07-20-group-admin-db-tabs-unification|dna-sql-agent-web 세션 로그]] 참고).

## 수행한 작업

1. **커넥션 목록 서버 페이지네이션** — `/group-admin/connections/paged` 신설
   (`group_admin/crud.py`에 `get_connections_for_group_ids_paged`, `LIMIT/OFFSET`
   + `exclusively_owned` 판정 포함)
2. **정책 변경 1차: "표시되는 건 다 권한 있다고 간주"** — 기존 "단독 소유 커넥션만
   수정/삭제 가능" 제한을 폐기, 그룹에 보이는 커넥션이면 공유 여부와 무관하게
   수정·삭제 허용하도록 변경. `docs/group-admin-design.md` §3.2/§4.1 갱신, 변경
   이력 0.4 추가
3. **시스템 목록 서버 페이지네이션** — `/group-admin/systems/paged` 신설, 시스템도
   `exclusively_owned`(다른 그룹과 공유되는 시스템인지) 계산해 응답에 포함
4. **버그: `SystemScopeResponse` 스키마 빌드 실패** — `SystemResponse.vectorization_jobs`의
   forward-ref(`list["JobStatus"]`)가 서브클래스가 정의된 `group_admin/models.py`
   모듈 네임스페이스에서 해석되는데 거기 `JobStatus`가 import 안 돼 있어서 첫 요청에서
   500 → `JobStatus` import 추가로 해결
   → 지식화: [[knowledge/troubleshooting/pydantic-forward-ref-resolved-in-subclass-module]]
5. **권한 체크 전수 감사** (사용자 요청 "데이터베이스 그 api들 다 권한 체크 되어있어?")
   — `group_admin/routes.py` 전체를 훑어 시스템/커넥션/SQL예제/벡터라이즈/멤버/권한
   엔드포인트가 전부 스코프 체크(`_require_system_in_scope`, `_require_connection_visible`,
   `require_group_admin_for_group()`)를 거치는지 확인. **한 곳 구멍 발견**:
   `POST /group-admin/systems`(`create_my_system`)가 body의 `connection_id`를
   전혀 검증하지 않아, 그룹 관리자가 임의의(자기 그룹과 무관한) 커넥션 위에
   시스템을 만들 수 있었음 — `db_routes.create_system`도 "존재하고 active인지"만
   확인, 소유권은 안 봄
6. **정책 변경 2차: 커넥션 접근 임시 전면 개방** — 위 구멍을 고치려고 "생성자만
   수정 가능"(created_by 컬럼 신설) 방향으로 스키마 마이그레이션까지 작성했다가,
   사용자가 "일단 시스템 관리자처럼 풀어두고 피드백 받고 나중에 고치자"고 방향
   전환 → 스키마 변경 되돌리고, `list/get/create/update/delete/test-connection`
   전부 `db_routes`의 시스템 관리자용 핸들러로 스코프 체크 없이 위임하도록 단순화.
   이걸로 5번의 구멍도 자연스럽게 해소(신규 시스템의 connection_id 제약이 정책상
   아예 없어짐). 관련 crud 함수(`get_connections_for_group_ids*`)와 응답 모델
   (`ConnectionScopeResponse` 등) 삭제
7. 커밋 3건 — 페이지네이션+권한감사 수정, 문서 갱신, 커넥션 전면개방(메시지에서
   "TODO 표시" 문구는 사용자 요청으로 제거)

## 핵심 결정

- **결정 1:** 그룹 관리자의 커넥션 접근 범위는 "생성자만 편집 가능"(개인 단위
  소유권, `created_by` 컬럼 신설)으로 설계하다가 **보류** — 스키마 마이그레이션까지
  작성했으나 사용자가 "임시로 시스템 관리자와 동일하게 전체 개방, 피드백 받고
  나중에 재조정"으로 방향 전환. 코드는 되돌렸고 설계만 알고 있는 상태 (아래
  "다음 할 일" 참고)
- **결정 2:** 시스템 생성 시 대상 `connection_id`에 대한 스코프 제약은 없음 —
  그룹 관리자는 어떤 커넥션 위에도 새 시스템을 만들 수 있다 (사용자가 명시적으로
  "제한 없음" 선택)

## 배운 것

- Pydantic v2에서 부모 모델의 forward-ref 필드는 **서브클래스가 정의된 모듈**의
  네임스페이스에서 해석된다 — 부모 모듈에 타입이 있어도 소용없다. `ast.parse`나
  타입체커로는 못 잡고, 실제로 그 모델을 한 번 인스턴스화해봐야(요청을 태워봐야)
  드러난다 → [[knowledge/troubleshooting/pydantic-forward-ref-resolved-in-subclass-module]]
- 권한 감사는 "각 엔드포인트가 뭔가 체크를 하는가"뿐 아니라 "그 체크가 실제로
  막아야 하는 입력(다른 사람 소유의 리소스 id를 body에 직접 넣는 경우)까지
  커버하는가"까지 봐야 한다 — `create_my_system`은 URL 경로 파라미터는 다 체크했지만
  body 안에 든 `connection_id`는 아무도 안 보고 있었다.
- 정책을 코드로 옮기기 전에 "이 조건을 만족 못 하는 기존 데이터/엣지케이스가
  뭐가 있는가"를 먼저 물어보는 게 좋다 — "생성자만 편집 가능" 설계 중 "created_by
  컬럼 신설 전 기존 커넥션은 누구 소유로 볼 것인가"를 사용자에게 물어봤고, 그
  대화 중에 "일단 그냥 다 열어두자"로 스코프가 축소됨. 큰 스키마 변경을 시작하기
  전에 이런 질문을 먼저 했으면 왕복이 줄었을 것 (다만 이 경우엔 질문 자체가
  스코프 축소의 계기가 됐으니 결과적으로는 유용했음).

## 문제 & 해결

- **문제:** `GET /group-admin/systems/paged` 호출 시 500 (`SystemScopeResponse is not
  fully defined`)
  **원인:** 위 "배운 것" 참고 — forward-ref 해석 모듈 스코프 문제
  **해결:** `group_admin/models.py`에 `from dna.database.models import JobStatus` 추가

## 다음 할 일

- [ ] `docs/group-admin-design.md` §4.1이 지금 실제 코드 상태(완전 개방)보다
      한 단계 전 버전(0.4: "표시되는 건 권한 있다고 간주하되 표시 자체는 그룹
      매핑 시스템 기준으로 필터링")에 머물러 있음 — 정책이 최종 확정되면 문서도
      다시 갱신 필요
- [ ] 그룹 관리자 커넥션 접근 범위 최종 정책 결정 — 후보로 "생성자만 수정/삭제"
      설계(스키마: `connections.created_by UUID REFERENCES users(id)`, 기존 행은
      NULL→시스템관리자 전용)가 있었으나 보류 상태. 재개할 경우 이 세션의
      백업(되돌린 마이그레이션 diff는 git 히스토리엔 없음, 이 로그의 커밋 5번
      설명이 유일한 기록이므로 재설계 시 참고)
- [ ] PR 생성 (백엔드 3커밋, 이번 세션분)
- [ ] `is_connection_exclusively_owned_by_group`(crud.py) — 오늘 정책 변경으로
      완전히 orphan된 함수, 테스트는 아직 참조 중. 커넥션 정책 최종 확정 시
      같이 정리할지 결정

## 효과적이었던 프롬프트

```
흠 일단 커넥션 관련 기능 - 그룹 관리자
=> 커넥션 표시는 슈퍼 어드민과 같이 필터링 없이 보이게
=> 수정, 삭제 권한은 본인이 생성한 것에만
```
