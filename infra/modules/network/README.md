# Network 추상 모듈

> 추상 인터페이스 — variables / outputs만 정의. 실제 resource는 provider별 root module(`aws/` · `nhn/` · `openstack/`)에서 wrapping.
>
> **이 패턴의 가치**: variables / outputs 시그니처가 같으면 root module을 바꿔도 상위 코드(예: `compute/`·`database/` 모듈에서 network 출력 참조) 영향 없음 = **추상화 사고 시그널** (PRD §4 20%).

## 사용 정책

- `variables.tf` — provider-neutral 입력 (CIDR / zone 정의 / 라벨)
- `outputs.tf` — provider-neutral 출력 시그니처 (vpc_id / public_subnet_ids / private_app_subnet_ids / private_db_subnet_ids / external_egress_subnet_ids / management_subnet_ids / security_group_ids map)
- `main.tf` — **본 모듈에는 없음**. provider별 root가 직접 resource를 정의하고 outputs.tf에 정의된 시그니처에 맞춰 값을 노출

## 의존 관계

```
root (aws|nhn|openstack)
  └─ networking resources (provider별)
       └─ outputs.tf 시그니처에 맞춰 값 노출
              ↓
       database / compute / storage 모듈 (root에서 가져다 씀)
```
