---
type: session-log
project: dna-sql-agent
date: 2026-08-10
duration:
focus: "라이선스 위조 위협모델 분석 + 서버 부트스트랩 로직 dna/app 분리(난독화)"
tools-used: [claude-code]
outcome: success
---

# 2026-08-10 — 라이선스 위조 위협모델 분석 & 부트스트랩 리팩터링

## 목표

- `scripts/generate_license.py`로 사용자가 키만으로 동일 라이선스를 재발급/위조할 수 있는지 검토
- 만료·갱신 시 라이선스가 어떻게 반영되는지 파악
- `main.py`에 평문으로 노출된 라이선스 강제 로직을 컴파일(난독화) 범위로 이동

## 수행한 작업

1. 라이선스 서명 구조 분석 — `dadap.<payload>.<sig>` (JWT형), HMAC-SHA256 대칭키(`DNA_LICENSE_SECRET`)
2. 위조 가능성 실증 — 시크릿을 쥔 고객은 자기 머신용 payload를 임의로 서명 가능(만료·한도 부풀리기). `.so`/`scripts` 은닉과 무관.
3. `license.key` 최신 스키마로 재발급 — 구 스키마(`mac_address`, `machine_id` 없음)는 검증 실패 → `hostname`+`machine_id` 쌍으로 재서명
4. 검증 출처 추적 — 런타임 검증은 **오직 `config/license.json`**만 봄. 키 파일은 `not_activated`일 때만 부트스트랩 소스.
5. 만료 테스트용 과거 만료 키 발급, 격리 config로 "config=만료 + 키파일=유효키 → 자동 반영 안 됨" 실증
6. `main.py`(1592줄) → `src/dna/app/` 패키지로 분리, `main.py`는 8줄 shim. PR #138 생성.

## 핵심 결정

- **결정 1:** 부트스트랩 로직을 `dna/app`으로 옮겨 Nuitka 컴파일 범위에 포함 → 라이선스 워치독·기동 게이트 난독화
  → ADR: [[decisions/033-bootstrap-logic-into-compiled-package]]
- **결정(권고):** HMAC 대칭키 한계 → Ed25519 비대칭 전환이 유일한 근본 해법 (미구현, `test_license_signature_forgery.py`가 xfail로 고정)

## 배운 것

- 서명 토큰(JWS/JWT)에서 payload가 base64로 평문 노출되는 건 **정상 설계** — 보안은 기밀성이 아니라 무결성에서 나옴
- 대칭 MAC은 검증키=서명키라, 검증 주체(고객)와 서명 주체(벤더)가 다르면 위조를 막을 수 없음 → [[knowledge/patterns/symmetric-mac-verifier-can-forge]]
- Dockerfile이 `find dna vanna`로 재귀 스윕하므로 `dna/` 아래 새 서브패키지는 자동으로 `.so` 컴파일됨 (Dockerfile 수정 불필요)

## 문제 & 해결

- **문제:** 서버 기동 시 `RuntimeError: Unsupported license key format` — 만료 에러가 아님
- **원인:** `config/license.json`의 `license_key` 앞에 `111`이 붙어 프리픽스가 `111dadap` → `_parse_license_key`가 형식 거부. (파싱·서명 통과 후에야 만료 판정에 도달하므로 여기서 막히면 만료는 볼 수 없음)
- **해결:** 정상 키로 재활성화
- **파생 문제(재발 가능):** 키 파일을 유효키로 교체해도 config가 `active/expired/invalid`면 자동 반영 안 됨 → [[issues/license-key-file-not-reapplied-when-config-present]]

## 다음 할 일

- [ ] (권고) 라이선스 서명 HMAC → Ed25519 비대칭 전환 검토
- [ ] (권고) 갱신 footgun 완화 — 자동활성화 게이트를 "config가 유효 active 아니면 키파일 재검토"로 확장
- [ ] `get_status()`가 `ValidationError`(구 스키마 캐시)를 못 잡아 기동 크래시 → `invalid` 폴백 처리
- [ ] PR #138 리뷰·머지

## 효과적이었던 프롬프트

```
"기존의 (payload, HMAC signature) 정답쌍만으로는 새 payload의 유효 HMAC을 만들 수 없다는데 넌 어찌함?"
→ 잘못된 프레이밍(정답쌍으로 크랙)을 정정하게 만든 핵심 반박. enabler는 정답쌍이 아니라 고객 서버의 시크릿임을 분리.
```
