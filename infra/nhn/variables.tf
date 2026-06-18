variable "auth_url" {
  type        = string
  description = "NHN Identity(Keystone) auth URL (NHN docs에서 확인)"
}

variable "region" {
  type        = string
  description = "NHN 공공 전용 리전명"
  default     = "KR1"
}

variable "tenant_name" {
  type        = string
  description = "NHN 프로젝트(테넌트) 이름"
}

variable "public_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "private_cidr" {
  type    = string
  default = "10.0.10.0/24"
}
