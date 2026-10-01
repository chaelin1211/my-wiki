---
type: issue-log
project: dna-sql-agent-deploy
created: 2026-08-28
---

# 소소한 문제 기록

파일로 남길 정도는 아닌 1회성·국소 문제. 한 줄씩 추가한다.

- 2026-08-28 `init.sh` 가 `폴더를 사용할 수 없습니다: ./log` 로 중단 → `mkdir -p` 는 성공했고(이미 존재) `[[ ! -w ]]` 에서 걸린 것. 설치 계정이 아니라 컨테이너 계정 소유였다. 이 중단 때문에 `[3/5] 이미지 불러오기` 가 실행되지 않아 폐쇄망에서 `docker compose up` 이 레지스트리 pull 로 실패
- 2026-08-28 `database "dnasql_agent" does not exist` 로 backend 재시작 반복 → postgres 공식 이미지의 `initdb` 는 데이터 폴더가 **빈 경우에만** `CREATE DATABASE $POSTGRES_DB` 를 한다. 이전 시도의 `data/postgres` 잔재로 통째로 건너뛰어짐. `psql -c "CREATE DATABASE dnasql_agent;"` 수동 생성으로 해결
- 2026-08-28 `Conflict. The container name "/dna-sql-agent" is already in use` 인데 `docker rm` 은 `No such container` → 컨테이너 생성 중 `Ctrl+C` 로 끊어 이름만 예약된 유령 레코드. `container_name` 을 바꾸거나 데몬 재시작으로 해소. vfs 환경에서는 생성이 길어 이 실수가 나기 쉽다
- 2026-08-28 `docker load` 를 세션 끊길 때마다 재시도해 동시 실행이 누적 → `dockerd` 가 237% 점유하며 아무것도 완료 못 함. `pkill -f "docker load"` 로 정리하고 하나만 `nohup` 으로 재실행해 해결
