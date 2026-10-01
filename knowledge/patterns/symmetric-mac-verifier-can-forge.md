---
type: knowledge-pattern
date: 2026-08-10
tags: [security, cryptography, licensing, hmac, signing]
---

# 대칭 MAC은 검증 주체가 곧 위조 주체가 된다

## 핵심

HMAC 같은 **대칭키 MAC은 서명키 = 검증키**다. 검증을 하려면 그 비밀키가 검증하는 쪽에 있어야 하고, 비밀키를 쥔 쪽은 **무엇이든 서명(위조)할 수 있다.** 따라서 "서명 주체(발급자)와 검증 주체(사용자)가 다른" 상황(라이선스, 오프라인 토큰, 클라이언트 배포 검증기)에서는 대칭 MAC이 위조를 원천 차단하지 못한다.

## 오해와 정정

- **오해:** "정품 (payload, signature) 정답쌍만으로는 새 payload의 유효 서명을 못 만든다 → 그러니 안전하다."
  - 이 문장 자체는 맞다(HMAC existential unforgeability). 하지만 안전의 근거가 아니다.
- **정정:** 위조의 enabler는 정답쌍이 아니라 **검증기 옆에 평문으로 있는 비밀키**다. 키를 쥐면 payload를 임의로 만들어 결정적으로 서명하면 된다. 정답쌍은 canonical 직렬화 규칙을 확인하는 보조 용도일 뿐.

## 감별 기준

> **"위조에 필요한 비밀이 검증 주체의 환경에 있는가?"**
> 있으면(대칭키·클라이언트측 pepper·payload 암호화 키) → 위조 가능.
> 없으면(비대칭 개인키를 발급자만 보유) → 위조 불가.

무력한 대응(전부 security through obscurity):
- 소스 난독화/컴파일(`.so`) — 규칙 알아내기만 조금 귀찮게
- payload 암호화 — 복호화 키가 클라이언트에 있으면 복호화→수정→재암호화 가능
- 서명 대상 메시지 변형/숨은 상수 — 검증기가 재현해야 하므로 클라이언트에 존재 → 리버싱·정답쌍 대조로 복원

## 해법

- **비대칭 서명(Ed25519 / RS256 등):** 발급자만 개인키 보유, 검증 주체엔 공개키만 배포 → 검증만 되고 서명 불가
- **온라인 검증(phone-home):** 발급자 서버가 실시간 판정 (상시 연결 필요)
- JWT 세계의 표준 권고와 동일: 서명자≠검증자면 HS256(대칭) 말고 RS256/EdDSA(비대칭)

## 사례

dna-sql-agent 라이선스가 HMAC-SHA256 대칭키(`DNA_LICENSE_SECRET`)라, 시크릿이 담긴 고객 서버에서 만료·한도를 부풀린 라이선스를 자가 서명 가능. `tests/test_license_signature_forgery.py`가 이 한계를 `xfail(strict)`로 고정 — Ed25519 전환 시 XPASS로 바뀜.

## 관련 페이지

- [[projects/dna-sql-agent/decisions/033-bootstrap-logic-into-compiled-package]]
- [[projects/dna-sql-agent/issues/license-key-file-not-reapplied-when-config-present]]
