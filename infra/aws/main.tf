/**
 * AWS root module — OfficeAgent 현행 유지 (비교용)
 *
 * AWS 현행 운영을 NHN root와 1:1 대비하기 위한 비교 baseline.
 * AWS provider는 성숙도 ★★★★★ — NHN root와 시그니처 비교가 추상화 사고 시그널.
 *
 * 본 PoC는 실 apply 없음 — validate + plan(-refresh=false)까지.
 */

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  # 자격증명은 환경변수 (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_PROFILE) 또는 IAM Role.
  # 실 apply 없으므로 인자 비어도 validate / plan PASS.
}
