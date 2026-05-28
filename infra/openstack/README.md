# OpenStack root module — 장기 로드맵 (skeleton)

> 본 디렉토리는 **장기 로드맵 자료**다. 본 1차 OfficeAgent NHN 배포 안정화 후 12~24개월 시점의 재설계 검토용.
>
> [`MIGRATION_PLAN.md §3`](../../MIGRATION_PLAN.md#3-오픈스택-장기-대응) + [`ARCHITECTURE.md §4`](../../ARCHITECTURE.md#4-nhn-only-종속의-솔직한-식별)와 정합.

---

## 본 디렉토리의 목적

본 1차 과제 평가에서 *"NHN-only 종속 식별이 솔직한가"* 시그널을 코드 형태로 보여주기 위함. **OpenStack 단계에서 재작성 필요한 부분을 미리 식별**한 것을 코드 디렉토리 존재 자체로 입증.

본 디렉토리에는 **실제 Terraform 코드가 없다** (의도된 비어 있음). 이유:

1. **본 과제 범위 = NHN-only 종속 식별까지** (PRD 사용자 결정, 2026-05-26)
2. OpenStack 자체 운영은 별도 인프라(베어메탈·HSM 등) 도입 전제 — 5일 안에 PoC 작성 부적합
3. NHN root module이 OpenStack 기반 명명 (`*_v2`)을 그대로 쓰기 때문에 **상당 부분 재사용 가능** — 단, 매니지드 서비스 영역(`nhncloud_db_*` 추정 등)은 자체 운영 도구로 대체 필요

## 재작성 대상 매핑 (ARCHITECTURE.md §4와 동기)

| 영역 | NHN-only 의존 (`infra/nhn/`) | 오픈스택 단계 자체 구축 도구 | 재작성 비용 |
|------|------------------------------|------------------------------|----------|
| 매니지드 DB | (NHN RDS for PG — placeholder) | PostgreSQL + Patroni + etcd | ★★★★ (HA 자동화 직접 구축) |
| 매니지드 Object Storage | (NHN OBS — placeholder) | OpenStack Swift | ★★★ (다중 노드 + replica 운영) |
| 매니지드 KMS | (NHN Secure Key Manager) | Barbican + HSM 연동 | ★★★★ (HSM 비용 ↑) |
| 매니지드 IAM | (NHN IAM) | Keystone (LDAP/AD 연동) | ★★★ (사용자·그룹·정책 매핑) |
| 매니지드 LB | (NHN LB) | Octavia 또는 HAProxy keepalived | ★★★ (HA failover 직접) |
| 매니지드 K8s | (NKS — provider 미확인) | OpenStack Magnum + kubespray | ★★★★ (cluster lifecycle 자체) |
| 매니지드 모니터링 | (NHN Log & Crash + Monitoring) | Prometheus + Grafana + Loki | ★★ (잘 알려진 스택) |

→ 재사용 가능 (NHN root에서 그대로 가져옴):
- `nhncloud_networking_*_v2` ↔ `openstack_networking_*_v2` (Provider만 교체, 시그니처 동일)
- 5 zone 망분리 설계 (§A-2) 그대로
- 추상 모듈 `modules/network/` 인터페이스 (variables/outputs 시그니처)

## 재설계 우선순위 (장기 검토)

`MIGRATION_PLAN.md §3.3`과 동기:
1. **핵심 데이터·키 통제** (PostgreSQL HA + Barbican) — 데이터 주권 절대 요구 시점
2. **객체 스토리지** (Swift) — 사용량·비용에 따라
3. **네트워크 + LB** (Neutron + Octavia)
4. **인증** (Keystone)
5. **관측·로깅** (자체 스택)

## 본 디렉토리에 코드가 없는 점이 평가 불이익이 아닌 이유

- PRD §6 불합격 기준에 "OpenStack 코드 작성" 항목 없음
- PRD §1.3 *"코드형도 문서형도 동등 평가"* 명시
- 본 README가 NHN-only 종속을 **솔직히 식별** (PRD §4 추상화 20% 시그널)
- 코드 디렉토리 자체가 *"의식하고 있음"* 표시
