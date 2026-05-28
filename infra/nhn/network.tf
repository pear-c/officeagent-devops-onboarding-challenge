/**
 * NHN Network — VPC + 5 zone Subnet + 5 Security Group
 *
 * MIGRATION_PLAN.md §A-1 (VPC↔NHN VPC 매핑) + §A-2 (5 zone 망분리)와 1:1 대응.
 * Provider: nhn-cloud/nhncloud (OpenStack 기반 명명, *_v2 prefix).
 *
 * 본 파일이 정의하는 자원:
 *   - networking_network_v2  × 1 (VPC)
 *   - networking_subnet_v2   × 5 (zone별)
 *   - networking_secgroup_v2 × 5 (zone별)
 *   - networking_secgroup_rule_v2 × N (zone 간 통신 규칙)
 *
 * 미정의(별도 자원·docs 직접 확인 후 보강):
 *   - Internet Gateway / Router (networking_router_v2)
 *   - NAT Gateway (NHN docs 미명시 — Day 5 보강)
 */

# ─── VPC ────────────────────────────────────────────────────────────────────

resource "nhncloud_networking_network_v2" "vpc" {
  name           = "${var.service_name}-${var.environment}-vpc"
  admin_state_up = true
  tags           = [for k, v in var.common_tags : "${k}:${v}"]
}

# ─── 5 zone Subnet ──────────────────────────────────────────────────────────

resource "nhncloud_networking_subnet_v2" "public" {
  name       = "${var.service_name}-${var.environment}-public"
  network_id = nhncloud_networking_network_v2.vpc.id
  cidr       = var.zone_cidrs.public
  ip_version = 4
  tags       = [for k, v in merge(var.common_tags, { zone = "public" }) : "${k}:${v}"]
}

resource "nhncloud_networking_subnet_v2" "private_app" {
  name       = "${var.service_name}-${var.environment}-private-app"
  network_id = nhncloud_networking_network_v2.vpc.id
  cidr       = var.zone_cidrs.private_app
  ip_version = 4
  tags       = [for k, v in merge(var.common_tags, { zone = "private_app" }) : "${k}:${v}"]
}

resource "nhncloud_networking_subnet_v2" "private_db" {
  name       = "${var.service_name}-${var.environment}-private-db"
  network_id = nhncloud_networking_network_v2.vpc.id
  cidr       = var.zone_cidrs.private_db
  ip_version = 4
  tags       = [for k, v in merge(var.common_tags, { zone = "private_db" }) : "${k}:${v}"]
}

resource "nhncloud_networking_subnet_v2" "external" {
  name       = "${var.service_name}-${var.environment}-external"
  network_id = nhncloud_networking_network_v2.vpc.id
  cidr       = var.zone_cidrs.external
  ip_version = 4
  tags       = [for k, v in merge(var.common_tags, { zone = "external" }) : "${k}:${v}"]
}

resource "nhncloud_networking_subnet_v2" "management" {
  name       = "${var.service_name}-${var.environment}-management"
  network_id = nhncloud_networking_network_v2.vpc.id
  cidr       = var.zone_cidrs.management
  ip_version = 4
  tags       = [for k, v in merge(var.common_tags, { zone = "management" }) : "${k}:${v}"]
}

# ─── 5 Security Group (positive + stateful) ──────────────────────────────────

resource "nhncloud_networking_secgroup_v2" "public" {
  name        = "${var.service_name}-${var.environment}-sg-public"
  description = "Public zone — ALB. Inbound 443 from any. Outbound to private_app:8080."
}

resource "nhncloud_networking_secgroup_v2" "private_app" {
  name        = "${var.service_name}-${var.environment}-sg-private-app"
  description = "App zone — OfficeAgent Pods. Inbound 8080 from public SG. Outbound to private_db + external + Object Storage."
}

resource "nhncloud_networking_secgroup_v2" "private_db" {
  name        = "${var.service_name}-${var.environment}-sg-private-db"
  description = "DB zone — RDS + Cache. Inbound 5432 + 6379 from private_app SG. Outbound = deny all (LLM 호출 금지)."
}

resource "nhncloud_networking_secgroup_v2" "external" {
  name        = "${var.service_name}-${var.environment}-sg-external"
  description = "외부 통신 zone — LLM API egress. Inbound from private_app SG. Outbound 443 to Anthropic/OpenAI (마스킹 후)."
}

resource "nhncloud_networking_secgroup_v2" "management" {
  name        = "${var.service_name}-${var.environment}-sg-management"
  description = "관리 zone — Bastion. Inbound 22 from 운영자 IP. Outbound to all private SGs (운영 점검)."
}

# ─── Zone 간 통신 규칙 (§A-2 망분리 정책) ─────────────────────────────────────
# 본 PoC는 핵심 룰 4개만 명시. 실 운영 시 11~15개 룰로 확장 필요.

# Public → App :8080
resource "nhncloud_networking_secgroup_rule_v2" "app_from_public" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_group_id   = nhncloud_networking_secgroup_v2.public.id
  security_group_id = nhncloud_networking_secgroup_v2.private_app.id
  description       = "App zone receives traffic from Public zone (ALB) only"
}

# App → DB :5432
resource "nhncloud_networking_secgroup_rule_v2" "db_from_app_pg" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5432
  port_range_max    = 5432
  remote_group_id   = nhncloud_networking_secgroup_v2.private_app.id
  security_group_id = nhncloud_networking_secgroup_v2.private_db.id
  description       = "DB zone receives PostgreSQL traffic from App zone only"
}

# App → External (egress)
resource "nhncloud_networking_secgroup_rule_v2" "external_from_app" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_group_id   = nhncloud_networking_secgroup_v2.private_app.id
  security_group_id = nhncloud_networking_secgroup_v2.external.id
  description       = "External (LLM egress) zone receives HTTPS from App zone only — 마스킹 라이브러리 경유"
}

# Management → All private (SSH from Bastion)
resource "nhncloud_networking_secgroup_rule_v2" "app_from_mgmt_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = nhncloud_networking_secgroup_v2.management.id
  security_group_id = nhncloud_networking_secgroup_v2.private_app.id
  description       = "App zone receives SSH from Bastion (관리망) for 운영 점검"
}
