---
type: session-log
project: dna-sql-agent-deploy
date: 2026-08-26
duration:
focus: "고객사에서만 임베딩 모델을 못 찾는 문제 원인 규명 (미해결)"
tools-used: [claude-code]
outcome: partial
---

# 2026-08-26 — 고객사 임베딩 모델 미탐지 원인 규명

## 목표

동일한 패키지 zip 인데 개발 서버에서는 기동되고 고객사(폐쇄망)에서는
`[EMBEDDING] ... 에 모델이 없어 huggingface.co 에서 내려받습니다` 가 찍히며
기동에 실패하는 원인을 찾는다.

## 증상

```
[EMBEDDING] /data/apps/dna_sql_agent/models/upskyy/bge-m3-korean 에 모델이 없어
            huggingface.co 에서 내려받습니다.
HTTPSConnection(host='huggingface.co', port=443) Failed to resolve 'huggingface.co' [Errno -3]
urllib3 NameResolutionError
```

`Errno -3` / `NameResolutionError` 는 폐쇄망이라 당연한 후속 증상이고, 원인이 아니다.
진짜 질문은 "왜 그 앞단에서 로컬 `models/` 를 못 찾았는가" 였다.

## 확인한 것 (모두 정상)

- **패키지 zip 원본** — `zipinfo` 로 확인. 구조·이름·크기·권한 전부 정상.
  `drwxrwxr-x models/upskyy/bge-m3-korean/`, `-rw-rw-r-- config.json`,
  `model.safetensors` 2,271,064,456 바이트. 심링크 0개
- **`package.sh --with-models` 의 반입 방식** — `hf download --local-dir` 로
  standalone 다운로드. HF 캐시의 `blobs/`+`snapshots/` 심링크 구조를 만들지 않는다.
  구버전 CLI 분기에는 `--local-dir-use-symlinks False` 명시
- **압축** — `zip` 은 `-y` 없이는 심링크를 따라가 실제 내용을 저장하므로 안전
- **마운트** — `docker inspect` 의 Source/Destination 정상
- **`license_files`** 는 같은 조건에서 정상적으로 읽힘

## 좁혀진 원인 후보

`resolve_model_path()` 의 판정은 `os.path.isfile(MODEL_ROOT/<model>/config.json)`
하나뿐이다. 이 값이 `False` 가 되는 경로는 셋뿐이다.

1. **앱 계정(UID 1005)이 모델 경로를 읽거나 통과하지 못함** ← 가장 유력
2. `config/embedding.json` 의 `model` 값이 폴더 이름과 다름
   (관리자 화면에서 변경 가능하고, `config/` 는 바인드 마운트라 고객사 파일이 살아남는다)
3. 압축이 덜 풀렸거나 `--with-models` 없이 만든 패키지

1번이 유력한 이유는 **`models/` 만 소유권 자가치유에서 빠져 있기** 때문이다.
`docker-entrypoint.sh` 의 chown 목록은 `config`·`log`·`hf_cache`·`query-results`
넷뿐이고 `models` 는 없다. `:ro` 마운트라 넣어도 chown 이 안 된다.

## 배운 것

- **개발 서버에서 이 문제가 안 드러난 이유가 우연이었다.** `stat` 결과가
  `1005 1005 775` — 압축을 푼 계정의 UID 가 마침 앱 UID(1005)와 같아서
  owner 비트로 읽히고 있었다. 그래서 `chmod o-rx` 재현 시험도 무효였다
  (owner 에겐 여전히 `rwx`). 고객사는 설치 계정 UID 가 다를 것이고,
  그러면 **other 비트로만** 접근한다
- **`os.path.isfile()` 은 권한 부족을 예외로 올리지 않고 `False` 를 돌려준다.**
  그래서 "파일이 없음" 과 "읽을 수 없음" 이 같은 로그로 뭉개진다.
  → [[knowledge/troubleshooting/exists-check-masks-permission-denied]]
- **`docker compose exec` 는 entrypoint 를 거치지 않아 root 로 들어간다.**
  앱은 `setpriv` 로 1005 로 떨어져 돌기 때문에, root 로 `ls` 하면 보이는 파일도
  앱은 못 볼 수 있다. 진단은 반드시 `-u 1005` 로 해야 하고,
  실행 중인 UID 확인은 `exec ... id` 가 아니라 `ps -o uid,cmd` 로 봐야 한다
- **컨테이너 계정은 이름만 컨테이너 로컬이고 숫자는 커널 공유다.** 호스트에
  1005번 계정이 없어도 `chown 1005:1005` 는 유효하다. 예외는
  rootless Docker / userns-remap
- **맥(colima)에서는 바인드 마운트 권한이 강제되지 않는다.** `chmod o-rx` 를 걸어도
  컨테이너가 읽는다. 권한 버그가 구조적으로 안 보이는 환경이다
  → [[knowledge/tools/colima]]
- **`HF_HUB_OFFLINE` 미설정은 원인이 아니다.** 로컬 판정은 허깅페이스 호출
  이전에 파일시스템 검사로 끝나므로 이 값과 무관하다. 다만 폐쇄망에서
  DNS 타임아웃 후 무한 재시작 대신 즉시 명확한 오류를 내게 하는 효과는 있어
  넣을 가치는 있다

## 남은 것

- 고객사에서 `docker compose exec -u 1005 backend` 로 앱 시점 확인 (아래 명령)
- `[EMBEDDING]` 로그 줄에 실제로 찍힌 경로 문자열 확보
- 모델을 zip 그대로 썼는지 별도 반입했는지 확인 (README 가 별도 반입을 안내한다)
- 원인 확정 후 `init.sh` 에 모델 폴더 권한 보정·검증 추가

```bash
docker compose exec -u 1005 backend sh -lc \
  'cat config/embedding.json; echo ---; ls -ld models models/* models/*/*; echo ---; ls -l models/*/*/config.json'
docker compose logs backend | grep EMBEDDING
```

## 관련

- [[001-offline-embedding-model]]
- [[../issues/embedding-model-not-found-despite-correct-mount]]
- [[2026-08-18-offline-package-and-deploy-hardening]]
