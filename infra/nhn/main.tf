/**
 * NHN Cloud root module — OfficeAgent 신규 배포
 *
 * MIGRATION_PLAN.md §A-1·§A-2 의사결정 박스의 NHN VPC + 5 zone 망분리를
 * Terraform 코드로 검증한다. 실 apply 없음 — validate + plan(refresh=false)까지.
 *
 * Provider: nhn-cloud/nhncloud v1.0.9 (2026-05-26, MPL-2.0)
 * 참조: https://registry.terraform.io/providers/nhn-cloud/nhncloud/latest
 */

terraform {
  required_version = ">= 1.6"

  required_providers {
    nhncloud = {
      source  = "nhn-cloud/nhncloud"
      version = "~> 1.0"
    }
  }
}

# Provider configuration — placeholder.
# 실 자격증명은 terraform.tfvars (gitignore) 또는 환경변수 OS_* 로 주입.
# 본 PoC는 실 apply 없으므로 인증 인자가 비어 있어도 validate / plan(-refresh=false) PASS.
#
# 참고: NHN Cloud Terraform User Guide
#   https://docs.nhncloud.com/en/Compute/Instance/en/terraform-guide/
# (현재 docs 페이지가 redirect 이슈로 직접 fetch 미달성 — Day 5에 정확 인자 정정 후보)
provider "nhncloud" {
  region    = var.region
  auth_url  = var.auth_url
  user_name = var.user_name
  password  = var.password
  tenant_id = var.tenant_id
}
