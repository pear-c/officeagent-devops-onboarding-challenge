# infra/ — Terraform skeleton (선택 산출물, PRD §2)

OfficeAgent 멀티 환경 네트워크 IaC **skeleton**. 실 apply 없음(클라우드 계정 불필요) — `validate`/`fmt`/`plan` 산출물로 [`VALIDATION.md`](../VALIDATION.md) A-1 검증을 뒷받침한다.

## 구조

```
infra/
├── modules/
│   └── network/      # 공통 추상 모듈 (VPC/Subnet/3계층 SG) — NHN·온프레미스 공유
├── nhn/              # NHN root (중등급) — openstack provider를 NHN 엔드포인트로
└── openstack/        # 온프레미스 root (상등급·폐쇄망) — 같은 network 모듈 재호출
```

> **추상화 증거**: `nhn/`과 `openstack/`이 **동일한 `../modules/network`를 호출**한다. 환경 차이는 provider `auth_url`·CIDR 변수뿐. AWS는 `aws_*` 리소스라 이 모듈을 공유하지 않는다 → 공유 경계가 곧 NHN-only/공통 경계([`ARCHITECTURE.md`](../ARCHITECTURE.md)).

## 실행 (오프라인 vs 자격증명 필요)

| 명령 | 자격증명 | 용도 |
|------|:--------:|------|
| `terraform fmt -recursive -check` | 불필요 | 포맷 검사 |
| `terraform init -backend=false` | 불필요(provider 다운로드만) | provider 설치 |
| `terraform validate` | **불필요** | 구문·타입·참조 검증 ← A-1 핵심 |
| `terraform plan -refresh=false` | **필요**(provider 인증) | 실 리소스 계획 — 계정 있을 때만 |

```bash
cd infra/nhn
terraform fmt -recursive -check
terraform init -backend=false
terraform validate          # → "Success! The configuration is valid."
```

자격증명이 없으므로 **본 과제의 검증 증거는 `fmt` + `validate`** (오프라인). `plan` 기반 SG 흐름 jq 검증(A-1 (3))은 계정 보유 시 실행.

## 보안
- 자격증명(OS_USERNAME/OS_PASSWORD)은 **환경변수**로. 코드·tfvars에 평문 금지.
- `*.tfvars`(실값) gitignore, `*.tfvars.example`만 커밋.
- `.terraform.lock.hcl`은 init 후 **커밋**(provider 버전 고정).

## 한계 *[미확인]*
- NHN provider 확정: 본 skeleton은 openstack provider 채택(NHN=OpenStack 호환). NHN 전용 `nhncloud` provider source·version·리소스명은 NHN docs/Registry로 확인 필요.
- `auth_url` 등 엔드포인트 실값은 NHN docs 확인 대상.
- network 외 모듈(compute/data/secrets)은 미작성 — 본 skeleton은 A-1(네트워크) 검증 범위로 한정.
