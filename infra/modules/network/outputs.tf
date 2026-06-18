# 네트워크 모듈 출력 — 후속 모듈(compute/data)이 보안그룹·네트워크 ID를 참조.

output "network_id" {
  description = "가상 네트워크 ID"
  value       = openstack_networking_network_v2.this.id
}

output "public_subnet_id" {
  value = openstack_networking_subnet_v2.public.id
}

output "private_subnet_id" {
  value = openstack_networking_subnet_v2.private.id
}

output "alb_secgroup_id" {
  value = openstack_networking_secgroup_v2.alb.id
}

output "app_secgroup_id" {
  value = openstack_networking_secgroup_v2.app.id
}

output "db_secgroup_id" {
  description = "DB 보안그룹 ID — A-1 검증 대상(App에서만 5432)"
  value       = openstack_networking_secgroup_v2.db.id
}
