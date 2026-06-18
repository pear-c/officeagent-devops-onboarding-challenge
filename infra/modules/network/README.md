# modules/network

OfficeAgent 네트워크 추상 모듈. **NHN(OpenStack 호환)과 온프레미스 OpenStack이 공유**한다.

## 무엇을 만드는가
- 가상 네트워크 1개(=AWS VPC) + 퍼블릭/프라이빗 서브넷
- 3계층 보안그룹: `alb` / `app` / `db`
- 흐름 규칙: 인터넷→ALB(443) · ALB→App(8080) · **App→DB(5432) 만**

## 핵심 불변식 (VALIDATION A-1 검증 대상)
`db` 보안그룹은 `remote_group_id = app` 인 5432 ingress **하나만** 갖는다.
인터넷(`0.0.0.0/0`)에서 DB로 가는 ingress 규칙은 없다 → DB가 외부에 직접 노출되지 않음.

## 입력
| 변수 | 설명 | 기본값 |
|------|------|--------|
| `environment` | 리소스 이름 prefix | (필수) |
| `public_cidr` | 퍼블릭 서브넷 | `10.0.0.0/24` |
| `private_cidr` | 프라이빗 서브넷 | `10.0.10.0/24` |

## 왜 `openstack_*` 리소스인가
NHN Cloud는 OpenStack 기반이라 Neutron 리소스(`openstack_networking_*`)로 NHN·온프레미스를 **한 모듈로** 다룰 수 있다. AWS는 별도(`aws_*`) — 그래서 AWS root는 이 모듈을 공유하지 않는다(현행 유지). 이 "공유 여부"가 추상화 경계를 드러낸다.

> NHN 전용 `nhncloud` provider도 Registry에 존재할 수 있으나 source·version·리소스명은 **미확인** — 본 skeleton은 검증 가능성이 높은 openstack provider를 채택. 실제 배포 시 NHN docs로 provider 확정 필요.
