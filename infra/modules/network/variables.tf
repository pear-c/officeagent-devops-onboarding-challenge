# 네트워크 모듈 입력 변수 — 환경별 root module(nhn/openstack)이 주입한다.
# 공통 추상화: 어느 환경이든 "환경 이름 + 두 CIDR"만 다르고 토폴로지는 동일.

variable "environment" {
  type        = string
  description = "배포 환경 식별자 (예: nhn-kr1, onprem-prod). 리소스 이름 prefix로 사용"
}

variable "public_cidr" {
  type        = string
  description = "퍼블릭 서브넷 CIDR (ALB/NAT)"
  default     = "10.0.0.0/24"
}

variable "private_cidr" {
  type        = string
  description = "프라이빗 서브넷 CIDR (App/DB)"
  default     = "10.0.10.0/24"
}
