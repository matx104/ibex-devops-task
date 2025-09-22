# modules/compute/outputs.tf
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.docker_host.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.docker_host.arn
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.docker_host.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.docker_host.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.docker_host.public_dns
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.docker_host.instance_state
}

output "key_pair_name" {
  description = "Name of the EC2 key pair"
  value       = aws_key_pair.ec2_key_pair.key_name
}

output "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  value       = local_file.private_key.filename
}

output "ssh_connection_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.docker_host.public_ip}"
}

output "application_url" {
  description = "URL to access the deployed application"
  value       = "http://${aws_instance.docker_host.public_ip}"
}
