# Terraform PoC — OfficeAgent 멀티 환경 배포

> [`MIGRATION_PLAN.md §2.2 의사결정 박스 A-1·A-2·A-3`](../MIGRATION_PLAN.md#22-깊이-분석--a-네트워크보안)의 추상화 구조를 코드로 검증. [`VALIDATION.md §1.2 시나리오 A-2`](../VALIDATION.md#12-시나리오-a-2-vpc--서브넷--security-group-terraform-validate-pass)와 1:1 대응.
>
> **실 apply 없음** (PRD §3). `terraform fmt -recursive` + `terraform validate` + `terraform plan -refresh=false -input=false` 까지만.

---

## 구조

```
infra/
├── README.md                        (이 파일)
├── modules/                         추상 모듈 — provider 분기 없는 인터페이스
│   └── network/
│       ├── variables.tf             cidr_block / subnet_count / az_count
│       ├── outputs.tf               (개념적 — provider별 root에서 wrapping)
│       └── README.md                추상 모듈 사용 정책
├── aws/                             AWS root module (현행 유지, 비교용)
│   ├── main.tf                      provider aws
│   ├── network.tf                   VPC + Subnet × 5 zone + SG × 5
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example     placeholder
├── nhn/                             NHN root module (신규 추가, 핵심)
│   ├── main.tf                      provider nhncloud v1.0.9
│   ├── network.tf                   nhncloud_networking_network_v2 + subnet × 5 + secgroup × 5
│   ├── database.tf                  RDS for PostgreSQL — placeholder + Day 5 보강
│   ├── storage.tf                   Object Storage 버킷 — placeholder + Day 5 보강
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example     placeholder (auth_url / user_name 등)
└── openstack/                       장기 로드맵 skeleton
    └── README.md                    재작성 비용·자체 구축 도구 매핑 (코드 없음)
```

## 검증 명령 (사용자가 실행)

```bash
cd infra
terraform fmt -recursive

# NHN root
cd nhn
terraform init -backend=false
terraform validate
terraform plan -refresh=false -input=false -out=plan.tfplan
terraform show -no-color plan.tfplan > ../validation-artifacts/nhn-plan.txt

# AWS root
cd ../aws
terraform init -backend=false
terraform validate
terraform plan -refresh=false -input=false -out=plan.tfplan
terraform show -no-color plan.tfplan > ../validation-artifacts/aws-plan.txt
```

기대: 두 root 모두 `Success! The configuration is valid.`

## 변경 시 동기화

| 영역 | 동기 갱신 대상 |
|------|--------------|
| Network CIDR / Zone 추가 | `nhn/network.tf` + `aws/network.tf` + `MIGRATION_PLAN.md §A-1·A-2` |
| 새 NHN resource 사용 | `terraform.tfvars.example` + `variables.tf` 인자 추가 |
| Provider 버전 업그레이드 | `main.tf` + `.terraform.lock.hcl` (생성 후 커밋) |

## NHN-only 종속 식별 (이 PoC가 명시적으로 비교)

`infra/nhn/` 와 `infra/aws/` 의 차이가 곧 NHN-only 종속의 솔직한 식별:

| 자원 | AWS (`aws/`) | NHN (`nhn/`) | 오픈스택 (`openstack/`) |
|------|--------------|--------------|----------------------|
| VPC | `aws_vpc` | `nhncloud_networking_network_v2` | (Neutron 자체 운영) |
| Subnet | `aws_subnet` | `nhncloud_networking_subnet_v2` | (Neutron) |
| Security Group | `aws_security_group` | `nhncloud_networking_secgroup_v2` | (Neutron) |
| Load Balancer | `aws_lb` | `nhncloud_lb_loadbalancer_v2` (예상) | Octavia |
| RDS PostgreSQL | `aws_db_instance` | (별도 매니지드 — Day 5 직접 확인 필요) | Patroni 자체 |
| Object Storage | `aws_s3_bucket` | (별도 매니지드 — Day 5 직접 확인 필요) | Swift |
| KMS | `aws_kms_key` | `nhncloud_keymanager_secret_v1` | Barbican |
| IAM Role | `aws_iam_role` + `assume_role_policy` | **직접 등가 없음** (§A-3 발견) | Keystone |

→ AWS Trust Policy / AssumeRole 메커니즘이 NHN에 없는 점은 코드로도 명확해짐 (MIGRATION_PLAN §A-3).

## 알려진 한계 (Day 5 보강 후보)

1. **NHN RDS resource 명 불확실** — `nhncloud_db_*` 추정. Day 5에 registry 직접 확인 후 보강
2. **NHN Object Storage resource 명 불확실** — Swift 기반이라 `nhncloud_objectstorage_container_v1` 같은 패턴 가능
3. **NHN provider 인증 인자 정확성** — OpenStack 표준(`auth_url` / `user_name` / `password` / `tenant_id` / `region`) 추정. NHN Terraform User Guide 직접 인용 보강 필요
4. **실 apply 미수행** — placeholder 값으로 `validate`만. 실 자원 생성 시 별도 검증 라운드 필요

## 라이선스

- NHN Cloud Terraform Provider: MPL-2.0
- 본 PoC 자체: 과제 제출용 (별도 라이선스 명시 없음)
