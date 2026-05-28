/**
 * AWS root module — 입력 변수.
 *
 * NHN root와 같은 시그니처 (service_name / environment / vpc_cidr / zone_cidrs / common_tags)를 유지해
 * 같은 추상 인터페이스로 두 root를 운영할 수 있음을 시연.
 */

variable "region" {
  type        = string
  description = "AWS region. 서울 = ap-northeast-2."
  default     = "ap-northeast-2"
}

variable "service_name" {
  type        = string
  default     = "officeagent"
  description = "서비스명 라벨 prefix."
}

variable "environment" {
  type        = string
  description = "환경 라벨 — dev / stage / prod."
  default     = "prod"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR. NHN root와 동일 — 향후 peering 시 충돌 회피 정책에 따라 조정 가능 (A-1 의사결정 박스 §대안 1 참조)."
}

variable "zone_cidrs" {
  type = object({
    public      = string
    private_app = string
    private_db  = string
    external    = string
    management  = string
  })
  description = "5 zone CIDR — NHN root와 1:1 매핑."
  default = {
    public      = "10.0.10.0/24"
    private_app = "10.0.20.0/24"
    private_db  = "10.0.30.0/24"
    external    = "10.0.40.0/24"
    management  = "10.0.100.0/24"
  }
}

variable "common_tags" {
  type        = map(string)
  description = "공통 태그."
  default = {
    project    = "officeagent"
    managed_by = "terraform"
    csap_tier  = "n/a" # AWS 현행은 CSAP 대상 아님 — NHN root만 csap_tier=medium
  }
}
