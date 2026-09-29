resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Nginx (public) + app (localhost only, not network-exposed)"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port            = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
  description       = "All outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Note: there is no rule for var.app_port. The backend app binds to
# 127.0.0.1 only (see scripts/instance-user-data.sh), so it has no network
# exposure at all, even within the VPC, regardless of security group rules.
# This is a deliberate substitute for the separate-instance isolation used
# in the two-instance version of this project.