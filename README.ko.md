# 🧊 LakeStart — 명령어 하나로 뜨는 셀프호스팅 Iceberg 레이크하우스

> **Apache Iceberg 레이크하우스를 내 노트북/서버에서** — 클라우드 계정 없이, 벤더 락인 없이.
> `docker compose up` → 첫 `SELECT *`까지 **5일이 아니라 5분**.

[![ci](https://github.com/msk-psp/lakehouse-starter/actions/workflows/ci.yml/badge.svg)](https://github.com/msk-psp/lakehouse-starter/actions/workflows/ci.yml)

![데모: Iceberg 카탈로그 탐색과 gold 레이어 쿼리](docs/img/demo.gif)
*진짜 Iceberg 테이블 위에서 브라우저 SQL (밑단은 REST 카탈로그 + MinIO) — `make up && make seed && make transform`이 전부입니다.*

**[English README](README.md)**

---

## 왜 만들었나

Iceberg 레이크하우스를 "제대로" 세팅하려면 카탈로그, S3 호환 스토리지, 인제스천,
쿼리 엔진, 그리고 메달리온(bronze/silver/gold) 레이아웃을 전부 엮어야 합니다.
현실에서는 첫 쿼리를 돌리기까지 **며칠에서 몇 달**을 태웁니다.

LakeStart는 이 전부를 미리 엮어서 제공합니다:

- **학습** — AWS 없이 진짜 인프라에서 Iceberg를 배우기
- **프로토타입** — 클라우드 벤더에 커밋하기 전에 팀용 레이크하우스 검증
- **셀프호스팅** — 홈랩/온프렘 박스에서 작은 레이크하우스를 실제로 운영

전부 **오픈소스(Apache-2.0)**, 노트북에서 돌아갑니다.

## 구성 (무료 코어)

| 컴포넌트 | 역할 | 포트 |
|---|---|---|
| **MinIO** | S3 호환 오브젝트 스토리지 (데이터 레이크) | `9000` / 콘솔 `9001` |
| **Iceberg REST 카탈로그** | 모든 엔진이 바라보는 테이블 카탈로그 (내장 SQLite 백엔드) | `8181` |
| **DuckDB UI** | Iceberg 테이블 위 브라우저 SQL — 유일한 쿼리 엔진 | `4213` |
| **메달리온 변환** | Bronze → Silver → Gold SQL, 유닛테스트 포함 | — |

의도적으로 **Spark 없음**: DuckDB 단일 엔진이라 컨테이너가 적고, 시작이 빠르고,
전체 스택이 노트북 RAM에 들어갑니다.

```bash
git clone https://github.com/msk-psp/lakehouse-starter && cd lakehouse-starter
cp .env.example .env
make up        # 레이크하우스 전체 기동
make seed      # 샘플 데이터를 bronze에 적재 (pyiceberg)
make transform # bronze → silver/gold Iceberg 테이블 실체화
make sql       # → http://localhost:4213 열고: SELECT * FROM warehouse.gold.daily_activity;
```

## 내 데이터 넣기

CSV / Parquet / JSON 파일을 `./data/`에 넣고 UI에서 한 줄:

```sql
CREATE TABLE warehouse.bronze.weather AS
SELECT * FROM '/data/local/example_weather.csv';
```

이게 진짜 Iceberg 테이블입니다 — 스키마 자동 추론, MinIO 저장,
REST 카탈로그를 쓰는 어떤 엔진에서도 보입니다.

## 신뢰: 이게 진짜 돌아간다는 근거

매 push + **매주** CI에서 두 층으로 검증합니다 (upstream 이미지가 썩어도 잡아냄):

1. **유닛테스트** (`make test`, docker 불필요) — `transforms/`의 SQL을 인메모리
   DuckDB에서 알려진 입력→기대 출력으로 검증. 라이브 스택도 *같은 파일*을 실행.
2. **스모크 테스트** (`make smoke`, docker) — 전체 스택 기동 → 적재 → 변환 →
   gold 레이어를 UI와 동일한 배선으로 쿼리해서 값 검증.

## 무료 코어 vs 프로덕션 팩

위 코어는 **학습과 프로토타입**에 필요한 전부입니다. 프로덕션(베어메탈 K8s, HA,
GPU 컴퓨트, 리니지, 모델 레지스트리)은 다른 일이고, 그게 **[Production Pack](docs/PRO.md)**:

- **베어메탈 Kubernetes**에 전체 플랫폼을 단일 명령으로 배포하는 Pulumi(Python IaC)
- SPoF 컴포넌트(카탈로그, 스케줄러)의 **active-active HA**
- 단일노드 MinIO 대신 **SeaweedFS** NVMe/HDD 티어링
- 분산/GPU 학습용 **KubeRay**, **MLflow + DataHub**, 대규모 Airflow
- 운영 **런북**

→ 이 스택을 실제 프로덕션에서 운영하는 엔지니어가 만듭니다. 문의:
[vibrio0102@gmail.com](mailto:vibrio0102@gmail.com)

## 라이선스

코어: Apache-2.0.
