---
type: session-log
project: dna-sql-agent
date: 2026-06-30
duration:
focus: "북마크 표시 누락 수정 + flow/point 지도 시각화·데이터 목록 개선"
tools-used: [claude-code]
outcome: success
---

# 2026-06-30 — 북마크 표시 누락 수정 및 지도(flow/point) 시각화·목록 개선

## 목표

채팅에서 북마크 카드 표시 아이콘이 누락되는 문제 해결, flow/point 지도의 데이터 목록·범례·색상 등 UI 개선.

## 수행한 작업

1. **북마크 표시 누락 수정**
   - 원인: 채팅 진입 시 북마크 목록을 로드하지 않음(매핑 맵 비어 있음) + 로드해도 첫 20개만(페이지네이션) → 표시가 가끔/전부 누락
   - 백엔드: `GET /api/v1/bookmarks/refs?conversation_id=` 경량 조회 엔드포인트 추가(component_id↔id 쌍만, 페이지네이션 없음)
   - 프론트: 채팅 진입 시 해당 대화 북마크 refs 전체 로드 → 매칭 맵 채움
2. **flow map 범례 누락 수정 (회귀)**
   - 원인: "부가 컬럼 통과" 리팩터에서 `display_cols`가 from/to 라벨 컬럼을 제외하는데, flow는 `color` 기본값이 `from_label`이라 color 컬럼이 통째로 빠짐 → 라인에 카테고리 속성 없음 → 범례·색 안 나옴
   - 수정: color/value가 from/to 라벨과 같아 빠졌으면 항상 props에 보강
3. **점/툴팁 표시 개선**: datetime이 epoch 숫자로 직렬화되던 것 ISO로(`to_json(date_format="iso")`), 라벨 미지정 시 첫 식별 컬럼 자동 선택('(점)' 방지), 점 폴백 시 from_label을 라벨로
4. **데이터 목록(좌측) 재구성**: 점은 id로, 흐름선은 출발(from)로 묶어 접기/펼치기. `from==to` 한 기준으로 #2(O-D)/#3(경로) 분류. 선택 묶음 강조색.
5. **화살촉 보정 + 크래시 가드**: 화살표 머리를 화면상 선 길이 기준으로(짧으면 축소/<14px 생략), `_mapPane` 가드+try/catch로 `_leaflet_pos` 크래시 방지
6. **클러스터링**: 포인트 지도에만 활성화(`mapType==='point'`), 높은 줌(maxZoom-2)에선 클러스터 해제 → 촘촘한 트랙도 개별 점 확인
7. **팔레트**: 범주 색 5→10색 확장 + 순서 교차, 다크모드 전용 비비드 팔레트(흰색 혼합 폐기)
8. **도구 설명 보강**: color 인자에서 'Avoid ID/code columns' 제거, FLOW 형식에 `color=category(범례)` 안내 추가
9. **LIMIT 화면 안내 제거**: 자동 LIMIT 적용 시 화면 고지 제거(실행·LLM 인지·북마크 저장은 유지)
10. PR 생성: 백엔드 #90, 프론트 #64 (브랜치 `refactor/bookmark_map`)

## 핵심 결정

- **결정 1:** 지도 데이터 목록을 `from==to`로 분류 — 같으면 단일 경로(id 묶음), 다르면 O-D 흐름(출발 from 묶음). 점과 흐름이 섞이지 않게 from/id 하위로 라인을 접어 넣음.
  → ADR: [[decisions/019-flowmap-list-grouping]]
- **결정 2:** 다크모드는 라이트 색을 흰색과 혼합하지 않고 **별도 비비드 팔레트**를 둠 — 어두운 색이 허옇게 떠 서로 비슷해지는 문제 회피.
- **결정 3:** 클러스터링은 포인트 맵에만, 최대 줌 근처에선 해제 — 분포는 묶고, 촘촘한 트랙은 개별 점/흐름이 보이도록.

## 배운 것

- pandas `df.to_json(orient="records")`는 datetime64 컬럼을 **epoch 밀리초(숫자)** 로 직렬화한다 → `date_format="iso"` 필요.
- Leaflet `latLngToContainerPoint`는 지도 `_mapPane` 없을 때(언마운트·StrictMode 더블마운트) `_leaflet_pos` TypeError를 던진다 → 가드/try-catch 필요.
- cm 단위로 촘촘한 좌표는 타일 지도 최대 줌(≈18, 0.5 m/px)에서도 한 격자/픽셀에 뭉쳐 클러스터가 안 풀린다 — 줌만으로 분리 불가.

## 문제 & 해결

- **문제:** flow map에서 color를 줘도 범례가 안 뜸
- **원인:** `display_cols`가 from/to 라벨 컬럼 제외 + flow color 기본값이 from_label → color 컬럼 누락
- **해결:** color/value가 from/to와 같아 빠졌으면 props에 보강
  → 이슈: [[issues/flowmap-legend-color-equals-from-label]]

- **문제:** 채팅 북마크 표시 아이콘 누락
- **원인:** 채팅 진입 시 북마크 미로드 + 페이지네이션(20개)
- **해결:** 대화별 경량 refs 전체 조회 엔드포인트 + 진입 시 로드
  → 이슈: [[issues/bookmark-display-missing-on-chat-entry]]

## 다음 할 일

- [ ] PR #90·#64 리뷰·머지, 백엔드 재시작 후 동작 확인(datetime·범례·라벨은 재시작 필요)
- [ ] (별개 조사) 다중 쿼리 수행 내역이 새로고침/대화전환 시 사라지는 문제 — components 영속화 경합(`SaveComponentsMiddleware` ↔ `ChatSaveHook`), reload 복원이 components 컬럼만 의존(`build-steps.ts`)
- [ ] 0행 쿼리 결과 표시 정책(현재 미표시 유지) 재검토 여부

## 효과적이었던 프롬프트

```
(케이스를 3개로 분류해 좌측 목록 동작을 케이스별로 정리해달라 →
 from==to 한 기준으로 단순화 합의)
```
