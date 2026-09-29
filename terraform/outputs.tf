output "instance_public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.web.public_ip
}

output "instance_url" {
  description = "URL to test the reverse proxy"
  value       = "http://${aws_instance.web.public_ip}"
}

output "instance_id" {
  description = "Instance ID (for SSM Session Manager)"
  value       = aws_instance.web.id
}