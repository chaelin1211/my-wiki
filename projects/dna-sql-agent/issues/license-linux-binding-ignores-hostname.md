---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-25
resolved: true
root-cause: "Linux 판정 경로는 hostname 을 보지 않고 machine_id + (cpu_model 또는 mem_total) 로 판정하는데, 맥·윈도우 경로의 규칙(둘 다 비면 통과)과 혼동해 두 필드를 비워 발급함"
tags: [license, fingerprint, docker, colima, local-test]
---

# 다른 PC 로 발급된 라이선스로 배포 패키지가 기동되지 않음 — 재발급 규칙 정리

## 증상

배포 패키지를 맥에서 기동하면 백엔드만 크래시 루프에 빠진다. web·nginx·postgres·qdrant 는 정상이다.

```
RuntimeError: 현재 사용 중인 PC에 등록된 라이선스가 아닙니다. 서버 시작이 차단되었습니다.
Replacement license.json failed: 400: 라이선스를 활성화할 수 없습니다.
현재 사용 중인 PC에 등록된 라이선스 키가 아닙니다.
```

## 환경

- 맥(Apple Silicon) + colima, 배포 패키지 `docker compose`
- `license_files/license.json` 이 개발 서버 기준으로 발급된 상태

## 근본 원인

두 겹이다.

**1. 라이선스는 컨테이너가 아니라 호스트 VM 에 묶인다.** compose 가 `/etc/machine-id`·`/proc/cpuinfo`·`/proc/meminfo` 를 마운트하므로, 맥에서는 colima VM 의 값이 잡힌다. 다른 PC 로 발급된 키는 당연히 어긋난다.

**2. 판정 규칙이 OS 별로 다르다.** `service.py` 의 `_payload_matches_current_machine` 은 이렇게 갈린다.

- **Linux** — `machine_id` 가 일치해야 하고, 그다음 `cpu_model` **또는** `mem_total` 중 **하나는 반드시 일치**해야 한다. **hostname 은 보지 않는다.**
- **맥·윈도우** — hostname 이 일치해야 하고, `cpu_model`·`mem_total` 이 둘 다 비어 있으면 통과한다.

컨테이너 안은 항상 Linux 이므로 Linux 규칙을 탄다. 맥·윈도우 규칙("둘 다 비면 통과")으로 오인해 두 필드를 비워 발급하면 `any(...)` 가 False 가 되어 튕긴다.

`_optional_field_matches` 는 양쪽 값이 모두 비어 있지 않고 같을 때만 참이다.

```python
return bool(payload_value.strip() and current_value.strip() and payload_value.strip() == current_value.strip())
```

## 해결 방법

컨테이너가 계산하는 지문을 직접 뽑아 그 값으로 발급한다.

```bash
docker exec dna-sql-agent sh -c 'cd /data/apps/dna_sql_agent && python -c "
import sys; sys.path.insert(0, \"src\")
from dna.license.fingerprint import get_machine_identity
print(get_machine_identity())"'
```

`machine_id` 와 `mem_total` 을 템플릿(`src/dna/license/customer_json_template/license.standard.template.json`)에 채우고 호스트에서 서명한다. `scripts/` 는 `.dockerignore` 에 있어 이미지 안에는 발급 스크립트가 없으므로, 컨테이너 안에서 `--bind-current-machine` 을 쓰는 길은 막혀 있다.

```bash
python3 scripts/generate_license.py --license-file <payload>.json --output-file license.json
```

arm64 에서는 `/proc/cpuinfo` 에 `model name` 이 없어 `cpu_model` 이 빈 값이다. 따라서 `mem_total` 한 축에만 의존하게 되고, **VM 메모리를 바꾸면 라이선스가 깨진다.**

## 관련

- 같은 VM 위라면 컨테이너를 지우고 새로 만들어도 유지된다. `colima delete` 후 재생성하면 machine-id 가 바뀌어 무효
- 라이선스를 검사하는 것은 백엔드뿐이다
- [[projects/dna-sql-agent/issues/license-key-file-not-reapplied-when-config-present]]
