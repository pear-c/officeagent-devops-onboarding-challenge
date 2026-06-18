# OfficeAgent 네트워크 추상 모듈 (NHN · 온프레미스 OpenStack 공용)
#
# 설계 의도: AWS의 VPC + Subnet + Security Group(ALB→App→DB) 토폴로지를
# OpenStack Neutron 리소스로 동형 이식. NHN Cloud는 OpenStack 호환이라
# 같은 모듈을 NHN root(infra/nhn)와 온프레미스 root(infra/openstack)가 공유한다.
#
# 핵심 불변식: DB 보안그룹은 App 보안그룹에서 오는 5432만 허용.
# 인터넷(0.0.0.0/0)에서 DB로 가는 ingress 규칙은 "존재하지 않는다".
# → VALIDATION A-1 이 이 불변식을 정적 검증한다.

terraform {
  required_version = ">= 1.6"
  # 자식 모듈도 provider source를 명시해야 root와 같은 provider로 해석된다.
  # (없으면 Terraform이 hashicorp/openstack 으로 오인 — init 실패)
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

# --- 가상 네트워크(=AWS VPC) ---
resource "openstack_networking_network_v2" "this" {
  name           = "${var.environment}-officeagent-net"
  admin_state_up = true
}

# 퍼블릭 서브넷: ALB / NAT 용
resource "openstack_networking_subnet_v2" "public" {
  name       = "${var.environment}-public"
  network_id = openstack_networking_network_v2.this.id
  cidr       = var.public_cidr
  ip_version = 4
}

# 프라이빗 서브넷: App / DB 용 (인터넷 직접 노출 금지)
resource "openstack_networking_subnet_v2" "private" {
  name       = "${var.environment}-private"
  network_id = openstack_networking_network_v2.this.id
  cidr       = var.private_cidr
  ip_version = 4
}

# --- 3계층 보안그룹 (AWS Security Group 대응) ---
resource "openstack_networking_secgroup_v2" "alb" {
  name        = "${var.environment}-alb"
  description = "인터넷 -> ALB (443)"
}

resource "openstack_networking_secgroup_v2" "app" {
  name        = "${var.environment}-app"
  description = "ALB -> App (8080)"
}

resource "openstack_networking_secgroup_v2" "db" {
  name        = "${var.environment}-db"
  description = "App -> DB (5432) 만 허용. 인터넷 직접 접근 차단"
}

# --- 흐름 규칙: ALB <- 인터넷(443) ---
resource "openstack_networking_secgroup_rule_v2" "alb_https_in" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.alb.id
}

# --- 흐름 규칙: App <- ALB(8080) ---
# remote_group_id 로 "ALB 보안그룹에서 오는 트래픽"만 허용 (IP가 아니라 그룹 기준)
resource "openstack_networking_secgroup_rule_v2" "app_from_alb" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_group_id   = openstack_networking_secgroup_v2.alb.id
  security_group_id = openstack_networking_secgroup_v2.app.id
}

# --- 흐름 규칙: DB <- App(5432) 만 ---
# ★ 이 규칙이 remote_group_id=app 이고, db 보안그룹엔 0.0.0.0/0 규칙이 없다.
#   VALIDATION A-1 의 jq 검증이 바로 이 불변식을 확인한다.
resource "openstack_networking_secgroup_rule_v2" "db_from_app" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5432
  port_range_max    = 5432
  remote_group_id   = openstack_networking_secgroup_v2.app.id
  security_group_id = openstack_networking_secgroup_v2.db.id
}
