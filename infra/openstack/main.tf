# 온프레미스 OpenStack root module (CSAP 상등급 · 물리 망분리 · 폐쇄망)
#
# NHN root와 "같은 network 모듈"을 호출한다 — 코드 재사용 = 추상화의 증거.
# 차이는 (1) auth_url 이 사내 Keystone (2) 폐쇄망이라 외부 egress 없음 (3) 리전 개념 없음.

terraform {
  required_version = ">= 1.6"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53"
    }
  }
}

provider "openstack" {
  auth_url    = var.auth_url # 사내 폐쇄망 Keystone 엔드포인트
  tenant_name = var.tenant_name
}

module "network" {
  source       = "../modules/network"
  environment  = "onprem"
  public_cidr  = var.public_cidr
  private_cidr = var.private_cidr
}

# 주: 상등급에서는 키관리(Vault)·관측(Prometheus)·관리형 DB(직접 설치)가
#     NHN-only 종속을 대체하는 별도 모듈로 추가된다(ARCHITECTURE §4). 본 skeleton은 network 만.

variable "auth_url" {
  type        = string
  description = "사내 OpenStack Keystone auth URL"
}

variable "tenant_name" {
  type    = string
  default = "officeagent"
}

variable "public_cidr" {
  type    = string
  default = "10.20.0.0/24"
}

variable "private_cidr" {
  type    = string
  default = "10.20.10.0/24"
}
