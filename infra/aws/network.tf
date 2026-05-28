/**
 * AWS VPC + 5 zone Subnet + 5 Security Group
 *
 * NHN root와 1:1 비교용. 같은 5 zone (public / private_app / private_db / external / management).
 * AWS는 SG rule이 stateful + AssumeRole로 IAM 권한 메커니즘 매끄러움 — NHN과의 차이가 §A-3 핵심.
 */

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.common_tags, {
    Name = "${var.service_name}-${var.environment}-vpc"
  })
}

# ─── 5 zone Subnet ──────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.zone_cidrs.public
  availability_zone = "${var.region}a"
  tags = merge(var.common_tags, {
    Name = "${var.service_name}-${var.environment}-public"
    zone = "public"
  })
}

resource "aws_subnet" "private_app" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.zone_cidrs.private_app
  availability_zone = "${var.region}a"
  tags = merge(var.common_tags, {
    Name = "${var.service_name}-${var.environment}-private-app"
    zone = "private_app"
  })
}

resource "aws_subnet" "private_db" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.zone_cidrs.private_db
  availability_zone = "${var.region}a"
  tags = merge(var.common_tags, {
    Name = "${var.service_name}-${var.environment}-private-db"
    zone = "private_db"
  })
}

resource "aws_subnet" "external" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.zone_cidrs.external
  availability_zone = "${var.region}a"
  tags = merge(var.common_tags, {
    Name = "${var.service_name}-${var.environment}-external"
    zone = "external"
  })
}

resource "aws_subnet" "management" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.zone_cidrs.management
  availability_zone = "${var.region}a"
  tags = merge(var.common_tags, {
    Name = "${var.service_name}-${var.environment}-management"
    zone = "management"
  })
}

# ─── 5 Security Group ───────────────────────────────────────────────────────

resource "aws_security_group" "public" {
  name        = "${var.service_name}-${var.environment}-sg-public"
  description = "Public zone — ALB. Inbound 443 from any."
  vpc_id      = aws_vpc.this.id
  tags        = var.common_tags
}

resource "aws_security_group" "private_app" {
  name        = "${var.service_name}-${var.environment}-sg-private-app"
  description = "App zone — ECS Fargate. Inbound 8080 from public SG."
  vpc_id      = aws_vpc.this.id
  tags        = var.common_tags
}

resource "aws_security_group" "private_db" {
  name        = "${var.service_name}-${var.environment}-sg-private-db"
  description = "DB zone — RDS + ElastiCache. Inbound 5432 + 6379 from private_app SG."
  vpc_id      = aws_vpc.this.id
  tags        = var.common_tags
}

resource "aws_security_group" "external" {
  name        = "${var.service_name}-${var.environment}-sg-external"
  description = "외부 통신 zone — LLM API egress. NHN root와 정합."
  vpc_id      = aws_vpc.this.id
  tags        = var.common_tags
}

resource "aws_security_group" "management" {
  name        = "${var.service_name}-${var.environment}-sg-management"
  description = "관리 zone — Bastion."
  vpc_id      = aws_vpc.this.id
  tags        = var.common_tags
}

# ─── 핵심 SG 룰 (NHN root와 동일 의도) ─────────────────────────────────────────

resource "aws_security_group_rule" "app_from_public" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public.id
  security_group_id        = aws_security_group.private_app.id
  description              = "App zone receives traffic from Public zone (ALB) only"
}

resource "aws_security_group_rule" "db_from_app_pg" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private_app.id
  security_group_id        = aws_security_group.private_db.id
  description              = "DB zone receives PostgreSQL traffic from App zone only"
}

resource "aws_security_group_rule" "external_from_app" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private_app.id
  security_group_id        = aws_security_group.external.id
  description              = "External egress zone receives HTTPS from App zone only — 마스킹 라이브러리 경유"
}

resource "aws_security_group_rule" "app_from_mgmt_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.management.id
  security_group_id        = aws_security_group.private_app.id
  description              = "App zone receives SSH from Bastion (관리망)"
}
