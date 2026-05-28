/**
 * NHN root module — 입력 변수
 *
 * 본 PoC는 실 apply 없음 — 모든 인증 인자는 placeholder. terraform.tfvars.example 참고.
 */

# ─── Provider 인증 (terraform.tfvars 또는 환경변수로 주입) ─────────────────────

variable "region" {
  type        = string
  description = "NHN region. 판교=KR1 / 평촌=KR2 / 광주=KR3(추정) / 도쿄=JP1."
  default     = "KR1"
  validation {
    condition     = contains(["KR1", "KR2", "KR3", "JP1"], var.region)
    error_message = "region은 KR1 / KR2 / KR3 / JP1 중 하나."
  }
}

variable "auth_url" {
  type        = string
  description = "NHN Identity API endpoint. OpenStack Keystone v2/v3. 정확한 URL은 NHN docs Terraform User Guide 참조."
  default     = "https://api-identity-infrastructure.nhncloudservice.com/v2.0"
  sensitive   = false
}

variable "user_name" {
  type        = string
  description = "NHN Cloud 계정 이메일 또는 IAM user_name."
  sensitive   = true
}

variable "password" {
  type        = string
  description = "NHN Cloud 계정 비밀번호 또는 application credential secret."
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "NHN Cloud 프로젝트(tenant) ID."
  sensitive   = true
}

# ─── 네트워크 (§A-1·§A-2 의사결정 박스와 정합) ─────────────────────────────────

variable "service_name" {
  type        = string
  description = "서비스명 라벨 prefix."
  default     = "officeagent"
}

variable "environment" {
  type        = string
  description = "환경 라벨 — dev / stage / prod."
  default     = "prod"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR. NHN 제약: RFC 1918 + 최소 /24."
  default     = "10.0.0.0/16"
}

variable "zone_cidrs" {
  type = object({
    public      = string
    private_app = string
    private_db  = string
    external    = string
    management  = string
  })
  description = "5 zone CIDR — 관리·Public·App·DB·외부 통신."
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
    csap_tier  = "medium"
  }
}
