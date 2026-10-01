---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-10
resolved: true
root-cause: "런타임 검증은 config/license.json만 읽고, 키 파일은 config가 not_activated일 때만 부트스트랩된다"
related: [decisions/033-bootstrap-logic-into-compiled-package]
tags: [license, deployment, operations]
---

# 라이선스 키 파일 교체로는 갱신·만료 복구가 안 됨

## 증상

- 만료된 서버에 유효한 새 `license_files/license.key`를 넣고 재기동해도 서버가 계속 안 뜸
- 기동 로그: `RuntimeError: License has expired. Server startup is blocked.` (또는 config 손상 시 `Unsupported license key format.`)
- 새 키가 정상 서명·머신 일치인데도 반영되지 않음

## 환경

- **런타임:** dna-sql-agent 서버 (`python src/main.py`)
- **관련 파일:** `config/license.json`(활성화 캐시), `license_files/license.key`(부트스트랩 소스)
- **재현 조건:** `config/license.json`이 이미 존재하고 상태가 `active`/`expired`/`invalid` 중 하나일 때 키 파일만 교체

## 시도한 것들

1. ❌ `license_files/license.key`를 유효키로 덮고 재기동 — 반영 안 됨
2. ✅ config를 비운 뒤(`not_activated`) 재기동 → 키 파일 자동 활성화
3. ✅ 또는 API/CLI로 직접 활성화

## 근본 원인

- **런타임 검증(`get_status`)은 오직 config의 `license` 섹션만 읽는다** (`load_stored()` → `settings_manager.load("license")`). 키 파일은 검증 대상이 아니다.
- 키 파일 자동 활성화(`_activate_license_from_default_file`)는 **`status == "not_activated"`일 때만** 키 파일을 읽어 config에 쓴다. config가 expired/invalid/active면 게이트에서 `return`.
- 게다가 만료 상태면 기동 게이트(`require_server_startup_ready`)가 먼저 `RuntimeError`로 서버를 막는다.
- 즉 "새 `license.key` 놓고 재시작"은 **최초 활성화 때만** 참이고, 갱신/만료 복구엔 거짓. 문서(`license-operations-guide.md`)의 자동 활성화 설명이 최초 1회만 유효한 점이 오해를 부름.

## 해결 방법

세 가지 중 하나로 config를 갱신:

```
# 1) API (무중단, 권장, admin 권한)
POST /api/v1/license/activate  { "license_key": "<dadap...>" }

# 2) CLI (조건 없이 덮어씀)
python src/main.py --license-file license_files/license.key

# 3) 비활성화 후 재기동 (not_activated → 키파일 자동 활성화)
POST /api/v1/license/deactivate   # 또는 config/license.json 삭제
```

## 예방책

- (권고) 자동활성화 게이트를 "config가 유효 `active`가 아니면 키 파일 재검토(서명·머신·날짜 OK인 더 나은 키면 교체)"로 확장하면 "키 파일 교체 후 재시작" 직관이 실제로 동작
- 납품 문서에 "갱신은 키 파일 교체가 아니라 API/CLI/재활성화"임을 명시

## 관련 페이지

- [[decisions/033-bootstrap-logic-into-compiled-package]]
- [[knowledge/patterns/symmetric-mac-verifier-can-forge]]
