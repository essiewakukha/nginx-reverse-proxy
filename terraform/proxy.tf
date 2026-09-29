resource "aws_instance" "proxy" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.proxy.id]
  iam_instance_profile        = aws_iam_instance_profile.proxy.name
  associate_public_ip_address = true

  # Referencing aws_instance.app.private_ip makes Terraform create the app
  # server first, then render the proxy script with the app's address in it.
  user_data = templatefile("${path.module}/scripts/proxy-user-data.sh", {
    app_private_ip = aws_instance.app.private_ip
    app_port       = var.app_port
  })

  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.project_name}-proxy"
  }
}