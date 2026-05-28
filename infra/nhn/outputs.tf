/**
 * NHN root module — 출력
 *
 * 다른 모듈(database / compute)이 이 root의 network 자원을 참조할 때 사용.
 * 시그니처는 modules/network/outputs.tf와 일치 (provider-neutral 인터페이스).
 */

output "vpc_id" {
  description = "NHN VPC ID."
  value       = nhncloud_networking_network_v2.vpc.id
}

output "public_subnet_ids" {
  description = "Public zone subnet IDs (ALB / ingress)."
  value       = [nhncloud_networking_subnet_v2.public.id]
}

output "private_app_subnet_ids" {
  description = "App zone subnet IDs (워크로드)."
  value       = [nhncloud_networking_subnet_v2.private_app.id]
}

output "private_db_subnet_ids" {
  description = "DB zone subnet IDs."
  value       = [nhncloud_networking_subnet_v2.private_db.id]
}

output "external_subnet_ids" {
  description = "External egress zone subnet IDs (LLM API 호출 격리)."
  value       = [nhncloud_networking_subnet_v2.external.id]
}

output "management_subnet_ids" {
  description = "Management zone subnet IDs (Bastion)."
  value       = [nhncloud_networking_subnet_v2.management.id]
}

output "security_group_ids" {
  description = "Zone별 Security Group ID map."
  value = {
    public      = nhncloud_networking_secgroup_v2.public.id
    private_app = nhncloud_networking_secgroup_v2.private_app.id
    private_db  = nhncloud_networking_secgroup_v2.private_db.id
    external    = nhncloud_networking_secgroup_v2.external.id
    management  = nhncloud_networking_secgroup_v2.management.id
  }
}
