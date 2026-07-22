---
type: session-log
project: dna-sql-agent
date: 2026-07-09
duration: 장시간 (백엔드+프론트 교차 작업)
focus: "채팅 북마크 이동 네비게이터, 지도 point 선택 중복 수정, 대시보드 고정 날짜 감지·경고, 대시보드 드래그 성능 개선"
tools-used: [claude-code]
outcome: success
---

# 2026-07-09 — 채팅 북마크 이동, 지도 선택 중복, 대시보드 고정 날짜·드래그 성능

## 목표

1. 채팅방 안에서 북마크된 카드(차트/아티팩트)로 바로 이동하는 기능
2. (사용자 제보) 지도 시각화에서 좌표+속성이 같은 데이터가 많을 때 하나 선택하면 여러 점이 같이 눌리는 문제
3. (파생 질문) 대시보드 "기존 저장된 쿼리로 갱신" 기능이 LIMIT뿐 아니라 상대 날짜도 고정되는지 확인 → 대응
4. (사용자 제보) 대시보드 편집 모드에서 지도 위주 위젯 드래그·드롭 시 버벅임

## 수행한 작업

1. **채팅 북마크 이동 네비게이터** (dna-sql-agent-web)
   - 기존 검색 결과 이동 인프라(`scrollToMessageIndex`, 메시지 하이라이트 플래시)를 재사용
   - `lib/bookmark-matches.ts` 신규 — 메시지 목록에서 북마크된 컴포넌트(chart/chart_dx/chart_ec/chart_map/artifact)가 있는 메시지를 순서대로 추출
   - 헤더에 북마크 토글 버튼(북마크 있을 때만 노출) → 이전/다음 원형 버튼으로 무한 순환 이동, 개수만 표시(순번 표시 안 함 — 북마크는 검색과 달리 추가/삭제로 순서가 바뀔 수 있어서)
   - 검색 중에는 비활성화(disabled + Tooltip 안내, `aria-disabled`로 hover는 살아있게)
   - `useBookmarks`의 `mapVersion`을 모든 북마크 변경 지점에서 갱신하도록 고쳐 네비게이터가 실시간 반영되게 함

2. **지도 point 선택 중복 수정** — [[issues/map-point-duplicate-selection-same-coords-and-properties]]
   - 원인: 프론트 `featureId()`가 좌표+`properties` JSON.stringify로 id를 만드는데, `properties`는 LLM이 조회한 컬럼만 담겨서 좌표+표시값이 완전히 같은 행이면 id가 겹침
   - 해결: 백엔드가 행 위치 기반 `Feature.id`(GeoJSON 표준 top-level id)를 항상 부여, 프론트는 `f.id` 우선 사용(없으면 구버전 캐시 폴백)

3. **상대 날짜 SQL 고정 문제 + 대시보드 고정 날짜 감지** — [[decisions/022-relative-date-dynamic-sql-and-fixed-date-detection]]
   - 발단: "대시보드 갱신이 LIMIT뿐 아니라 상대 날짜도 고정되는 거 아니냐"는 질문에서 실제로 시스템 프롬프트가 "기준 일시로 계산해서 SQL 작성"을 지시해 리터럴 날짜가 박히는 걸 확인
   - 시스템 프롬프트 지시를 "상대 날짜는 `CURRENT_DATE`/`INTERVAL` 등 DB 동적 함수로" 쓰도록 변경(절대 기간은 기존대로 리터럴)
   - 프롬프트만으론 LLM 준수를 보장할 수 없어 안전망으로: 저장된 쿼리에 날짜 리터럴이 있으면 대시보드 위젯 API가 `has_fixed_date_literal`을 내려주고, 프론트가 위젯 푸터/확대 팝업에 경고 아이콘(⚠️ TriangleAlert, amber) + 툴팁 표시

4. **북마크 삭제 시 대시보드 위젯 미동기화** — [[issues/dashboard-widget-stale-after-bookmark-deleted]]
   - DB는 `dashboard_widgets.bookmark_id ON DELETE CASCADE`라 북마크 삭제 시 위젯도 cascade 삭제되지만, 이미 열어둔 대시보드 화면은 `activeId`가 안 바뀌면 재조회를 안 해서 옛 목록을 계속 보여줌
   - `useBookmarks`에 `onBookmarkRemoved` 콜백 추가 → 북마크가 실제 삭제될 때(토글 해제/북마크 뷰 제거) 활성 대시보드가 있으면 즉시 `loadDetail` 재호출

5. **대시보드 드래그·드롭 성능 개선** — [[issues/dashboard-drag-drop-jank-heavy-widgets]], [[knowledge/patterns/react-grid-drag-memoize-heavy-children]]
   - 드래그 중 리렌더: `onLayoutChange`가 프레임마다 state를 갱신해 위젯 전체(지도 포함)가 매번 리렌더 → `DashboardWidget`을 `React.memo`로, `handleRemoveWidget`을 `useCallback`으로 고정
   - 드롭 순간 스터터: `.react-grid-item`에 `will-change: transform`이 드래그 중인 위젯에만 걸려있어 재배치되는 다른 위젯은 GPU 레이어 승격 없이 매 프레임 다시 그려짐 → 전체 `.react-grid-item`에 `will-change: transform` 적용
   - 여전히 남은 지연: `GridLayout`에 넘기는 `gridConfig`/`dragConfig`/`constraints`/`resizeConfig`가 매 렌더 새 객체/배열이라 라이브러리가 "변경"으로 인식 → `useMemo`/모듈 상수로 고정

## 핵심 결정

- **결정 1:** 상대 날짜는 프롬프트 지시(동적 함수 유도) + 감지·경고 UI 안전망을 함께 둔다(파싱 기반 자동 치환은 시도하지 않음 — SQL 리라이팅은 오탐/오작동 리스크가 큼)
  → ADR: [[decisions/022-relative-date-dynamic-sql-and-fixed-date-detection]]

## 배운 것

- Radix `Tooltip.Arrow`는 내부적으로 `<svg>`라, CSS `border`를 주면 실제 삼각형이 아니라 SVG의 사각형 바운딩 박스 전체에 테두리가 그려짐 — 꼬리에 테두리를 넣고 싶으면 stroke/drop-shadow 등 다른 접근이 필요(이번엔 안 함)
- `will-change`는 브라우저에게 "곧 transform이 바뀔 거다"라고 미리 알려 GPU 레이어로 승격시키는 힌트일 뿐, 코드로 직접 승격을 트리거하는 게 아님
- 드래그앤드롭 라이브러리(react-grid-layout)에 넘기는 설정 props가 매 렌더 새 객체/배열이면, 그 값 자체가 안 바뀌어도 라이브러리 내부에서 "바뀐 것"으로 취급해 불필요한 재계산이 생길 수 있음 — 자식 `React.memo`뿐 아니라 서드파티에 넘기는 props도 참조 안정성이 중요

## 문제 & 해결

- **문제:** 지도 point 목록에서 번호로 구분되는 점들이 하나 선택 시 다 같이 눌림
- **원인:** 좌표+properties가 완전히 동일한 행이 있어 프론트 `featureId`가 충돌
- **해결:** 백엔드가 행 위치 기반 Feature.id 부여, 프론트는 그걸 우선 사용
  → 이슈: [[issues/map-point-duplicate-selection-same-coords-and-properties]]

- **문제:** 채팅/북마크 뷰에서 북마크 해제해도 이미 열어둔 대시보드에서 위젯이 안 사라짐
- **원인:** DB cascade는 정상 동작하지만 프론트 대시보드 상태가 재조회를 안 함(activeId 불변 가드)
- **해결:** 북마크 삭제 성공 콜백에서 활성 대시보드 재조회
  → 이슈: [[issues/dashboard-widget-stale-after-bookmark-deleted]]

- **문제:** 대시보드 편집 모드에서 지도 위젯 드래그·드롭이 버벅임
- **원인:** (1) 드래그 중 매 프레임 전체 위젯 리렌더 (2) 드롭 재배치 애니메이션이 GPU 레이어 승격 없이 실행 (3) 그리드 라이브러리 설정 props가 매 렌더 새 참조
- **해결:** React.memo/useCallback, will-change: transform, useMemo/모듈 상수로 참조 고정
  → 이슈: [[issues/dashboard-drag-drop-jank-heavy-widgets]]

## 다음 할 일

- [ ] PR #104(백엔드), #69(프론트) 리뷰·머지 대기
- [ ] (이월) 대시보드 드래그 성능 — 사용자 체감상 "완전히는 아니지만 나쁘지 않다" 수준, 추가 여지 있으면 재검토(예: 위젯 수 많을 때 가상화, 드래그 중 지도 인터랙션 임시 비활성화 등)
- [ ] (이월) `feat/chat-bookmark-navigator` 등 여러 브랜치가 세션 중 외부에서 rename/merge되는 걸 목격 — 브랜치 관리가 여러 곳에서 동시에 일어나고 있다면 충돌 방지책 필요할 수 있음(정보 공유 차원, 액션 아이템은 아님)

## 효과적이었던 프롬프트

```
그 지도 시각화에서 ... 좌측 데이터 영역에 같은 id에 따라 묶음으로 데이터를 접어서
표시하고 넘버링 하잖아. 그 넘버링으로 구분되는 점들의 내부적인 키 값이 뭐야?
데이터 상으론 좌표, 이외의 정보가 일치하는 데이터가 꽤 돼서 좌측 넘버링은
많은데 누르면 다같이 눌려 아마 키 값이 중복되어서 그렇겠지
```
→ 증상+가설을 함께 주니 원인 코드 위치를 바로 특정할 수 있었음. "이 버튼 색이 이상해" 류보다 "무슨 값 기준으로 구분되는지" 같은 구조적 질문이 근본 원인 파악에 더 빠르게 이어짐.
