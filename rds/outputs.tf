# db에 대한 output_servername
output "DB_dns" {
  description = "DB Config dnsname"
  value       = aws_rds_cluster.MyRDS.endpoint
}

# db에 대한 user_name
output "DB_user" {
  description = "DB Config DB_user"
  value       = var.database_user
}
# db에 대한 password
output "DB_password" {
  description = "DB Config password"
  value       = var.database_password
  sensitive   = true
}