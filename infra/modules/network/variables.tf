/**
 * Network 추상 모듈 — provider-neutral 입력
 *
 * 본 모듈은 인터페이스 정의만 담당하고 실제 resource는 provider별 root에서.
 * MIGRATION_PLAN.md §A-1·§A-2 의사결정 박스의 5 zone 망분리와 정합.
 */

variable "service_name" {
  type        = string
  description = "서비스명 (라벨·태그 prefix). 예: officeagent"
  default     = "officeagent"
}

variable "environment" {
  type        = string
  description = "환경 (dev / stage / prod). 동일 service_name 안에서 분리"
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment는 dev / stage / prod 중 하나여야 합니다."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR (RFC 1918 사설 대역). 예: 10.0.0.0/16. NHN 제약: /24 이상."
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr은 유효한 CIDR 형식이어야 합니다 (예: 10.0.0.0/16)."
  }
}

variable "zones" {
  type = object({
    public         = string # ALB / Public ingress
    private_app    = string # 애플리케이션 워크로드
    private_db     = string # DB·Cache
    external       = string # 외부 통신 (LLM API egress 격리)
    management     = string # Bastion / 운영자 접근
  })
  description = "5 zone CIDR — MIGRATION_PLAN.md §A-2 망분리 설계와 1:1 매핑"
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
  description = "전 자원 공통 태그. 환경별 root에서 추가 필드 merge 가능"
  default = {
    project    = "officeagent"
    managed_by = "terraform"
    csap_tier  = "medium" # MIGRATION_PLAN.md 사용자 결정 사항
  }
}
