# 추상화 설계 — OfficeAgent 멀티 환경

> [`MIGRATION_PLAN.md`](./MIGRATION_PLAN.md)가 "**무엇을·언제·왜**"라면, 본 문서는 "**어떻게 추상화하면 같은 앱이 AWS·NHN·오픈스택에 배포되는가**". 깊이 도메인 A·B 중심.

---

## 1. 추상화 목표

단일 OfficeAgent 코드베이스를 **공통(provider-neutral) + 환경별 어댑터**로 분리해, 배포 환경(=고객 규제 등급)에 따라 어댑터만 교체한다.

- **공통 (provider-neutral)** — OfficeAgent 컨테이너 이미지(12-factor), 비즈니스 로직, 환경변수 설정, **추상화 인터페이스(포트)**: 네트워크·DB·오브젝트·캐시·키관리·관측·LLM 게이트웨이. 코드는 이 포트에만 의존한다.
- **AWS-only** — 현행 상용. ECS Fargate·RDS·S3·KMS·CloudWatch 어댑터.
- **NHN-only** — CSAP 중등급. NKS·RDS for PostgreSQL·Object Storage·Secure Key Manager·Log&Crash 어댑터.
- **오픈스택-only** — CSAP 상등급·폐쇄망. Nova/Magnum·PG 직접·Swift·Vault·Prometheus 스택 어댑터.

**핵심 원칙**: 앱은 "S3"를 부르지 않고 "오브젝트 스토리지 포트"를 부른다. 포트 뒤의 구현(S3 SDK / NHN S3호환 / Swift s3api)이 환경별 어댑터다. S3 호환 API 덕에 AWS·NHN은 같은 어댑터를 공유할 수 있고, 오픈스택만 op 차이를 흡수하는 별도 어댑터가 필요하다.

---

## 2. 다이어그램

### 2.1 영역 분리도

> **정식 산출물: [`assets/architecture-layers.drawio`](./assets/architecture-layers.drawio)** (draw.io). 4영역을 색으로 구분 — 공통(녹색) / AWS-only(주황) / NHN-only(노랑) / 오픈스택-only(파랑). 기능 슬롯 9개(네트워크·LB·컴퓨트·DB·오브젝트·캐시·키관리·관측·자격)를 행으로, 3환경을 열로 매핑하고, CSAP 등급·LLM 데이터 주권 콜아웃 포함.

drawio를 열 수 없는 환경을 위한 텍스트 요약:

```
[공통/녹색]  OfficeAgent 컨테이너 이미지 · 12-factor 설정 · 추상화 포트(네트워크/DB/오브젝트/캐시/키/관측/LLM게이트웨이)
                    │ (환경별 어댑터로 주입)
   ┌────────────────┼─────────────────────────────┐
[AWS-only/주황]  [NHN-only/노랑]            [오픈스택-only/파랑]
 ECS Fargate     NKS/NCS+NCR               Nova+Magnum/외부K8s
 RDS PG          RDS for PG (pg_dump)      Trove/Nova+Cinder 직접
 S3              Object Storage (S3호환)    Swift+s3api
 ElastiCache     EasyCache (영속성X)        Nova VM Redis
 KMS/SecretsMgr  ★Secure Key Manager       Vault/Barbican
 CloudWatch      ★Log&Crash+Monitoring     Prometheus/Grafana/Loki
 IAM             NHN 멤버권한               Keystone
```
`★` = NHN-only 종속(오픈스택 단계 재작성 대상, §4).

### 2.2 같은 애플리케이션이 환경별로 다르게 보이는 지점

| 추상화 포트 | AWS | NHN | 오픈스택 | 공통(앱이 보는 것) |
|------------|-----|-----|---------|-------------------|
| 오브젝트 스토리지 | S3 SDK | NHN S3호환(엔드포인트만 변경) | Swift s3api(op 차이 흡수) | `put/get/presign(bucket,key)` |
| DB 연결 | RDS 엔드포인트 | NHN RDS 엔드포인트 | 자체 PG 엔드포인트 | `DATABASE_URL` (env) |
| 캐시 | ElastiCache | EasyCache(영속성 없음 → 캐시 전용) | VM Redis | `REDIS_URL` (env) |
| 키/시크릿 | KMS/Secrets Manager | Secure Key Manager(IP/MAC/인증서) | Vault | `secret.get(name)` 포트 |
| 관측 | CloudWatch | Log&Crash + Monitoring | Prometheus/Loki | 구조화 로그(stdout) + OTLP |
| **LLM 호출** | 국외 직접 | **마스킹 게이트 경유** | **온프레미스/국내 모델** | `llm.complete(prompt)` 포트 |

> 가장 중요한 추상화는 **LLM 게이트웨이 포트**다. 앱은 `llm.complete()`만 부르고, 환경별 어댑터가 (AWS=직접 / NHN=PII 마스킹 후 국외 / 오픈스택=온프레미스 모델) 데이터 주권 정책을 구현한다. 이 한 포트가 §B-4 난제를 코드 변경 없이 환경별로 흡수한다.

---

## 3. 도구 의사결정

### 3.1 IaC 도구 선택

**채택: Terraform** (클라우드 계정 없이 `validate`/`plan -refresh=false`까지만, 실 apply 없음).

- **왜 Terraform인가**: AWS·NHN·OpenStack **세 provider를 한 도구로** 다룸(`hashicorp/aws`, `nhncloud/nhncloud`, `terraform-provider-openstack/openstack`). 모듈+변수로 공통/환경별 분리가 자연스러움. 검증 명령(`fmt`/`validate`/`plan`)이 산출물이 되어 §1.3 검증 점수 근거.
- **다른 후보와 단점 비교**:
  - **OpenTofu**: Terraform과 거의 동일(포크). NHN provider 호환성 검증 부담만 추가 → 보수적으로 Terraform.
  - **Pulumi**: 범용 언어(TS/Python) 장점이나 본 과제는 선언적 매핑이 핵심이라 학습비용 대비 이득 작음.
  - **Crossplane**: K8s 컨트롤 플레인 전제 → 오픈스택 폐쇄망 부트스트랩에 과함.
  - **Ansible**: 절차적 — 네트워크/스토리지 선언적 매핑 표현에 덜 적합. 단 오픈스택 OS 레벨 구성엔 보완재로 유용.

### 3.2 모듈 구조 (skeleton — 선택 산출물 `infra/`)

```
infra/
├── modules/
│   ├── network/     # VPC/Subnet/SG 추상 — NHN VPC ↔ OpenStack Neutron 변수화
│   ├── data/        # DB·오브젝트·캐시 포트
│   └── secrets/     # 키관리 포트
├── aws/             # AWS root module (현행 참조)
├── nhn/             # NHN root module (중등급)
└── openstack/       # OpenStack root module (상등급·폐쇄망)
```

> 실 apply 없이 `terraform validate` + `plan -refresh=false`로 모듈이 환경별로 분기됨을 입증한다(VALIDATION A 시나리오).

### 3.3 변수·환경 분리 전략

- **공통 변수**: 앱 이미지 태그, 포트, 리소스 사이징(CPU/메모리), 도메인.
- **NHN-only 변수**: 공공 전용 리전, Object Storage 엔드포인트(`kr1-api-object-storage...`), Secure Key Manager appkey, NKS 버전.
- **오픈스택-only 변수**: Keystone auth URL, 폐쇄망 내부 미러/프록시 엔드포인트, Octavia flavor, Swift 컨테이너.
- **시크릿·자격증명**: 코드/tfstate에 평문 금지. 환경변수·Vault/Secure Key Manager 주입. tfvars는 `*.tfvars.example`만 커밋, 실값 gitignore.

---

## 4. NHN-only 종속의 솔직한 식별 (추상화 사고의 핵심 시그널)

| 영역 | NHN-only 의존 | 오픈스택 대안 | 재작성 비용 |
|------|---------------|---------------|------------|
| **키 관리** | Secure Key Manager (IP/MAC/인증서 인증, NHN 전용 API) | Vault(권장) 또는 Barbican+HSM | **높음** — 키 추상화 포트 어댑터 신규 + HA 설계 |
| **관측** | Log&Crash Search + NHN Monitoring (로그/메트릭 분리) | Prometheus+Grafana+Loki 자체 | **높음** — 수집 파이프라인 전면 구축 |
| **관리형 K8s** | NKS/NCS (컨트롤플레인 매니지드) | 외부 K8s(Cluster API/kubeadm) on Nova | 중 — 클러스터 라이프사이클 자체 운영 |
| **관리형 DB** | RDS for PostgreSQL (백업/HA 매니지드) | Trove(미성숙) 또는 PG 직접 + 자체 백업 | **높음** — 무손실·복구·HA 자체 보장 |
| **로드밸런서** | NHN LB (매니지드) | Octavia (amphora=VM per LB) | 중 — 관리망·이미지·failover 운영 |
| **NAT/외부연결** | NAT Gateway (매니지드) | Neutron Router | 낮음 — 개념 동일 |
| **오브젝트** | Object Storage(S3호환) | Swift+s3api(에뮬레이션) | 중 — op별 호환성 대조 |
| 컨테이너 이미지·비즈니스 로직 | (종속 없음) | 그대로 재사용 | **없음 (공통)** |

> **읽는 법**: "재작성 비용 높음"이 많을수록 오픈스택 전환이 비싸다. 그래서 키관리·관측·DB를 **포트로 추상화**해 두는 것이 NHN 단계의 투자다(§1). 이 표가 멀티 환경 추상화 평가(20%)의 직접 증거.

---

## 5. 운영 자동화·AIOps 통합 지점 (선택 — 미구현)

본 과제 범위에서는 설계만. LLM이 운영 루프에 들어가는 후보 지점(향후 PoC):
- **알람 진단**: NHN Monitoring/CloudWatch 알람 → LLM이 로그·메트릭 수집·요약 → 운영자에게 가설 제시.
- **드리프트 비교**: `terraform plan` diff → LLM이 의도치 않은 변경 설명.
- **비용 이상치**: 비용 메트릭 → LLM 이상 감지.

> ⚠️ 이 지점들 모두 **§B-4 데이터 주권 적용 대상** — 운영 로그에 PII가 있으면 마스킹 게이트 경유 필수.

---

## 6. 가정·미확인 영역

| 가정/미확인 | 영향 범위 | 리스크 | 검증 계획 |
|------------|----------|--------|----------|
| NHN provider(`nhncloud/nhncloud`) 성숙도·리소스 커버리지 | IaC skeleton 작성 가능 범위 | 일부 리소스 미지원 → 수동/콘솔 보완 | Terraform Registry provider 문서 + `validate` 시도 |
| NHN RDS PG `wal_level=logical` 허용 여부 | B-1 무중단 대안 가능성 | 2차안 불가 → pg_dump만 | NHN 기술지원 문의 |
| Swift s3api op별 호환성(presign·ACL) | 오브젝트 어댑터 정확도 | 앱 S3 호출 일부 실패 | `swiftstack/s3compat` op 대조 |
| Secure Key Manager BYOK 범위 | 데이터 주권 키 통제 주장 | 주장 약화 | docs 정독/문의 |
| WebFetch 차단 → 1차 자료 원문 미정독 | 인용 충실도 | Q&A 1차자료 축 | 캡처 단계 브라우저 직접 열람 |

---

## 7. 참고 자료

- 1차 자료·신뢰도 표기는 [`MIGRATION_PLAN.md` §8](./MIGRATION_PLAN.md) 참조 (NHN docs / OpenStack docs / law.go.kr·CSAP 고시).
- Terraform providers: `hashicorp/aws`, `nhncloud/nhncloud`, `terraform-provider-openstack/openstack` (Terraform Registry).
- wiki/는 출발점일 뿐 — 본문 인용처 아님.

---

_v1 (2026-06-17, 학습용). 다이어그램 정식본 = `assets/architecture-layers.drawio`. infra/ Terraform skeleton은 선택 산출물로 후속._
