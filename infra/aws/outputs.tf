/**
 * AWS root module — 출력
 *
 * NHN root와 같은 시그니처 (provider-neutral 인터페이스).
 */

output "vpc_id" {
  description = "AWS VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public zone subnet IDs."
  value       = [aws_subnet.public.id]
}

output "private_app_subnet_ids" {
  description = "App zone subnet IDs."
  value       = [aws_subnet.private_app.id]
}

output "private_db_subnet_ids" {
  description = "DB zone subnet IDs."
  value       = [aws_subnet.private_db.id]
}

output "external_subnet_ids" {
  description = "External egress zone subnet IDs."
  value       = [aws_subnet.external.id]
}

output "management_subnet_ids" {
  description = "Management zone subnet IDs."
  value       = [aws_subnet.management.id]
}

output "security_group_ids" {
  description = "Zone별 Security Group ID map."
  value = {
    public      = aws_security_group.public.id
    private_app = aws_security_group.private_app.id
    private_db  = aws_security_group.private_db.id
    external    = aws_security_group.external.id
    management  = aws_security_group.management.id
  }
}
