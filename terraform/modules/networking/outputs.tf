# modules/networking/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.default.id
}

output "subnet_id" {
  description = "ID of the first available subnet"
  value       = tolist(data.aws_subnets.default.ids)[0]
}

output "all_subnet_ids" {
  description = "List of all subnet IDs"
  value       = data.aws_subnets.default.ids
}

output "security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2_sg.id
}

output "security_group_arn" {
  description = "ARN of the EC2 security group"
  value       = aws_security_group.ec2_sg.arn
}
