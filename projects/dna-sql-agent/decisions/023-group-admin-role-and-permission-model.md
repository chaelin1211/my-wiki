---
type: decision-record
project: dna-sql-agent
date: 2026-07-16
status: accepted
superseded-by: ""
tags: [auth, permissions, group-admin]
---

# ADR-023: 그룹 관리자(Group Admin) 역할과 이중 레이어 권한 모델

## 맥락

시스템 사용자 증가로 시스템 관리자(`admin` 그룹)가 사용자 1명 단위로 시스템 접근
권한을 관리하는 부담이 커졌다. 그룹 단위로 일괄 처리하면서도 세부 관리가 가능한
위임 관리자가 필요해졌다. 전체 정책은 저장소 내 `docs/group-admin-design.md`
(v0.3, 코드와 함께 버전관리됨)에 상세 기술됨 — 이 ADR은 그중 구현에 영향을 준
핵심 구조적 결정만 요약한다.

## 선택지

### 옵션 A: 그룹 관리자를 별도 그룹으로 만든다
- **장점:** 기존 `"admin" in group_memberships` 패턴을 그대로 재사용 가능
- **단점:** 그룹 관리자는 원래 그룹 소속을 유지해야 하는데(자기 그룹의 일반
  사용자이기도 함) 별도 그룹으로 만들면 "어느 그룹의 관리자인가"를 표현할 수 없음.
  사용자가 동시에 두 그룹에 속하는 구조가 되어 "사용자는 반드시 하나의 그룹" 제약과
  충돌

### 옵션 B: 그룹 관리자를 기존 그룹 소속 위에 얹는 역할(관계 테이블)로 만든다
- **장점:** 그룹 소속과 관리자 역할을 분리해서 표현 — 그룹당 여러 관리자 가능,
  0명도 허용 가능, "어느 그룹의 관리자인지"가 명시적
- **단점:** 기존 `admin` 그룹 체크와는 다른, 완전히 새로운 인가 메커니즘이 필요
  (DB 조회 필요, JWT만으로 판단 불가)
- **비용/노력:** `group_admins` junction table + 신규 dependency 계층 필요

## 결정

**옵션 B를 선택한다.** `group_admins(group_id, user_id)` 관계 테이블로 그룹 관리자
역할을 표현하고, 실제 접근 판정은 여전히 기존 `user_system_permissions` 테이블
기준으로 하되 그 위에 그룹↔시스템 매핑(`group_system_mappings`)이라는 **정책 레이어**를
추가한다.

- `group_system_mappings`: 그룹이 원칙적으로 접근 **할 수 있는** 시스템의 범위(상한선).
  이 테이블만으로는 사용자에게 접근 권한을 주지 않는다 — 그룹 관리자가 이 범위 내에서
  개별 `user_system_permissions`를 부여해야 실제 접근이 가능해진다.
- 신규 사용자 편입 시 자동 부여는 `group_system_mappings.default_grant` 플래그로
  제어 (매핑과 1:1 관계라 별도 테이블 없이 한 테이블에 통합).

또한 `require_group_admin` 계열 인가 의존성은 **JWT claim이 아니라 매 요청마다
DB를 조회**하는 방식으로 구현했다 — 정책상 "그룹 관리자가 비활성화되면 즉시 역할
해제"가 요구되는데, JWT에 역할을 넣으면 토큰 TTL(기본 30분)만큼 지연이 생겨
정책을 어기게 된다.

## 근거

- 그룹 관리자가 "역할"이지 "소속"이 아니라는 정책 요구사항(§2)을 스키마 레벨에서
  정확히 표현하려면 관계 테이블이 필수적 — 그룹 문자열 비교만으로는 불가능.
- 그룹 매핑을 별도 레이어로 분리하면 기존 `user_system_permissions` CRUD를 코드
  변경 없이 그대로 재사용할 수 있어 회귀 위험이 적다 (기존 시스템 관리자 기능은
  완전히 무변경).
- DB 조회 기반 인가는 `require_admin`(순수 JWT)보다 비싸지만, 어차피 매 admin
  라우트가 DB 풀에 접근하므로 한 번의 추가 쿼리는 상대적으로 저렴하고, "즉시 반영"
  요구사항을 만족하는 유일한 방법이다.

## 결과

- 그룹 이동(편입/추방) 시 이전 권한을 그룹 매핑 여부와 무관하게 **전량 회수**하는
  정책(v0.3에서 확정)도 이 이중 레이어 구조 덕분에 단순한 트랜잭션(`move_user_group`)
  하나로 구현 가능했다.
- 향후 재검토 시점: 그룹 관리자가 여러 그룹을 관리하는 구조로 확장될 경우
  (`group_admins`는 스키마상 이미 다대다를 지원하지만 정책은 현재 "자기 그룹 1개"로
  제한) 프론트엔드의 `groupAdminGroupId`(단일 값 가정)를 배열로 바꿔야 한다.
- 영향받는 컴포넌트: `dna.auth.deps`, `dna.group_admin.*`(신규), `dna.auth.routes`의
  `update_user`/`register`/`me`, 프론트엔드 `useAuth()`의 역할 캐싱 전체.

## 참고 자료

- 저장소 내 정책 문서: `dna-sql-agent/docs/group-admin-design.md` (v0.3, 이후 v0.5까지 개정)
- 세션 로그: [[projects/dna-sql-agent/sessions/2026-07-16-group-admin-feature|2026-07-16-group-admin-feature]]
- **후속:** 커넥션 접근 권한 부분(§4.1)은 [[decisions/024-connection-delegation-model|ADR-024]]에서
  "그룹↔커넥션 위임" 레이어 신설로 재조정됨 — 이 문서의 관계 테이블 vs 역할 방식
  선택, DB 조회 기반 인가 등 나머지 내용은 그대로 유효
