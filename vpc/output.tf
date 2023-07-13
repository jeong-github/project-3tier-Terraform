output "vpc_id" {
  description = "My vpc"
  value       = aws_vpc.jch_vpc.id
}
output "jch_public_subnet1" {
  description = "my subnet1"
  value       = aws_subnet.jch_public_subnet1.id
}

output "jch_public_subnet2" {
  description = "my subnet2"
  value       = aws_subnet.jch_public_subnet2.id
}

output "jch_private_subnet1" {
  description = "my subnet1"
  value       = aws_subnet.jch_private_subnet1.id
}

output "jch_private_subnet2" {
  description = "my subnet2"
  value       = aws_subnet.jch_private_subnet2.id
}

output "jch_private_subnet3" {
  description = "my subnet3"
  value       = aws_subnet.jch_private_subnet3.id
}
output "jch_private_subnet4" {
  description = "my subnet4"
  value       = aws_subnet.jch_private_subnet4.id
}