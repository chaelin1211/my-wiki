---
type: session-log
project: dna-sql-agent
date: 2026-06-25
duration:
focus: "시스템 제외 테이블·테이블 접근 제어 목록 선택 UI (#68) 및 에이전트 설정 정리"
tools-used: [claude-code]
outcome: success
---

# 2026-06-25 — 제외 테이블/테이블 접근 제어 목록 선택 UI (#68) 및 설정 정리

## 목표

- (#68) 관리자 DB 시스템 관리에서 제외 테이블을 일일이 입력하던 방식 → 실제 테이블 목록을 조회·선택하는 방식으로 간편화
- 같은 패턴을 보안 > 테이블 접근 제어(차단/쓰기허용)에도 적용
- DB 연결 버전 정보 추가 및 LLM 메타 전달
- 에이전트 설정 화면 전반 정리(토스트 공통화·한글화, 리셋 버그, LLM 즉시저장)

## 수행한 작업

1. **백엔드 — 테이블 목록 조회 API** (`feat/connection-version`)
   - `GET /api/v1/db/connections/{id}/tables?schema=...` — dialect별 실제 테이블 목록 조회(oracle/postgres/mysql/sqlite), 연결 실패 시 502로 전파
   - `detect_schemas` 조회를 `list_tables`와 동일 소스로 통일: Oracle `all_tables`+`all_users.oracle_maintained='N'`, PostgreSQL `pg_tables` 직접 집계 → 누락 스키마 표시 해결
   - `get_available_systems`(권한용)에 `connection_id`·`schemas` 추가 + 정렬 `created_at DESC`로 시스템 관리와 통일
   - DB 연결에 `version` 컬럼 + 연결 테스트 시 자동 감지, 시스템 프롬프트에 `## 데이터베이스 메타 정보`(종류·버전) 주입
2. **프론트 — 제외 테이블 선택 UI** (`feat/system`)
   - 시스템 다이얼로그: 자유입력 → 사용/제외 트랜스퍼 리스트 → (상단 태그 미리보기 5개+"외 N개" + (+) 펼침 시 전체/선택 2단 패널)로 재구성
   - 스키마 입력을 detect-schemas 기반 드롭다운 체크박스 멀티셀렉트로 교체(테이블 수 표시, 직접 입력 fallback, 대소문자 무시 매칭+케이스 정규화)
   - 탭 분리(기본정보/제외테이블), 반응형(좁으면 2열→2행), 검색창 공통 컴포넌트화
3. **프론트 — 테이블 접근 제어** (보안 탭)
   - 차단/쓰기허용 테이블을 태그(테이블명+스키마 mute) 표시 + (+) 펼침 조회/검색/추가 방식으로 교체 (재사용 컴포넌트 `table-transfer-select.tsx`)
4. **에이전트 설정 정리**
   - 설정 리셋이 서버 기본값 초기화 → **마지막 저장값 복원**으로 수정
   - 테이블 접근 제어·인프라(도구/UI) 권한 **reset 미배선 버그** 수정
   - LLM 연결 활성화를 dirty-save → **즉시 저장**으로 통일(CRUD와 일관), foundation 탭은 SaveBanner 대신 안내 문구
   - 토스트 공통 스타일(CheckCircle2/AlertTriangle)·한글화, 아이콘 버튼 호버 색 통일(.icon-btn)
5. **PR**: 백엔드 `Closes #68`, 프론트 cross-repo `Related to ...#68` 매핑 안내

## 핵심 결정

- **제외/차단 테이블 저장은 `스키마.테이블` 형식, 매칭은 대소문자 무시.** 백엔드 `_is_excluded`/extractor가 `table.upper()` 또는 `owner.table.upper()`로 매칭하므로 UI도 동일. 직접 입력 시 단일 스키마면 `스키마.테이블`로 자동 보정(동명 테이블 오제외 방지).
- **`detect_schemas`와 `list_tables`를 동일 소스로 통일.** 둘이 다르면(스키마 권한 기반 vs all_tables) 목록·개수가 어긋남.
- **LLM 연결은 전부 즉시 저장.** dirty-save staging은 CRUD 즉시저장과 섞여 혼란 → 활성화도 즉시 저장으로 일관.
- **설정 리셋 = 미저장 변경 취소(저장값 복원)**, 서버 공장 초기화가 아님. (리셋 버튼이 "변경 있을 때만 활성"인 의도와 일치)

## 배운 것

- 권한 화면의 시스템 목록(`available-systems`)과 시스템 관리 목록(`getSystems`)은 별도 엔드포인트라 필드/정렬이 갈릴 수 있음 → 매핑 의존 말고 응답에 필요한 필드를 직접 포함시키는 게 안전.
- dirty-save 패턴에서 카드가 ref 기반 saveRef/onDirtyChange를 쓰면 **resetRef도 같이 배선**해야 "설정 리셋"이 동작. 누락 시 dirty가 안 풀려 버튼이 계속 활성.

## 문제 & 해결

- **문제:** sqlite 등 목록을 못 불러오는 시스템을 연 뒤 다른 시스템 다이얼로그를 열어도 오류가 잔류
- **원인:** 재오픈 시 상태 미초기화 + 느린 실패 응답이 새 시스템 상태를 덮어쓰는 race
- **해결:** 오픈 시 테이블/오류 상태 초기화 + 요청 토큰(reqRef)으로 stale 응답 무시
  → 이슈: [[issues/stale-error-and-race-on-dialog-reopen]]

- **문제:** 테이블 접근 제어/인프라 권한을 수정 후 "설정 리셋"을 눌러도 안 되돌아가고 리셋 버튼도 계속 활성
- **원인:** dirty는 집계되지만 reset ref가 배선되지 않아 변경 폐기 경로가 없음 + ctx.reset이 공장 초기화였음
- **해결:** resetRef 배선(저장값 복원) + ctx.reset을 originals 복원으로 변경
  → 이슈: [[issues/settings-reset-not-restoring-saved]]

## 다음 할 일

- [ ] 백엔드 PR(#68) 리뷰·머지 + 서버 재시작 (available-systems 응답 필드 의존)
- [ ] 프론트 PR 리뷰·머지
- [ ] (#68 후속) 제한 테이블을 추천 테이블 추출 시 함께 전달
- [ ] (#68 후속) SQL Guard 제한 테이블 DB화
- [ ] Oracle 11g(`oracle_maintained` 미지원) 환경 대비 폴백 필요 여부 확인

## 효과적이었던 프롬프트

```
(사용자가 UI 방향을 단계적으로 구체화)
"체크박스 말고 영역 두개로 해서 추가 삭제 이렇게 할까"
"태그가 너무 많아서 보기 힘든데 목록을 전체 목록 | 선택된 목록 이렇게 나누고
 위 태그로 표시되는 곳엔 몇개만 표시하고 + 눌러서 목록으로 보도록 유도하자"
```
