output "app_secgroup_id" {
  value = module.network.app_secgroup_id
}

output "db_secgroup_id" {
  description = "A-1 검증 대상 (App에서만 5432)"
  value       = module.network.db_secgroup_id
}
