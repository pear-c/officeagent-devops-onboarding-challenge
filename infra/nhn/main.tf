# NHN Cloud root module (CSAP 중등급 · 논리 망분리 · 공공 전용 리전)
#
# NHN Cloud는 OpenStack 호환 -> openstack provider를 NHN 엔드포인트로 설정.
# 공통 network 모듈을 그대로 호출한다(추상화 시연).

terraform {
  required_version = ">= 1.6"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53"
    }
  }
}

# 자격증명은 코드에 평문 금지 — 환경변수(OS_USERNAME/OS_PASSWORD) 또는
# tfvars(gitignore)로 주입. auth_url/region/tenant 만 변수로 노출.
provider "openstack" {
  auth_url    = var.auth_url    # NHN Identity(Keystone) 엔드포인트
  region      = var.region      # 공공 전용 리전 (예: KR1)
  tenant_name = var.tenant_name # NHN 프로젝트(테넌트)
}

module "network" {
  source       = "../modules/network"
  environment  = "nhn-${var.region}"
  public_cidr  = var.public_cidr
  private_cidr = var.private_cidr
}
