output "proxy_public_ip" {
  description = "Public IP of the Nginx proxy"
  value       = aws_instance.proxy.public_ip
}

output "proxy_url" {
  description = "URL to test the reverse proxy"
  value       = "http://${aws_instance.proxy.public_ip}"
}

output "proxy_instance_id" {
  description = "Instance ID of the proxy (for SSM Session Manager)"
  value       = aws_instance.proxy.id
}

output "app_private_ip" {
  description = "Private IP of the backend app (not reachable from the internet)"
  value       = aws_instance.app.private_ip
}