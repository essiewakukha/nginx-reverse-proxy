# Latest Amazon Linux 2023 AMI (standard, not minimal or ECS-optimized).
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.app.id]

  # Bootstrap script runs once at first boot (cloud-init).
  user_data = templatefile("${path.module}/scripts/app-user-data.sh", {
    app_port = var.app_port
  })

  # Changing the script replaces the instance so the new script actually runs.
  user_data_replace_on_change = true

  # Require IMDSv2 (session-token based metadata access).
  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.project_name}-app"
  }
}