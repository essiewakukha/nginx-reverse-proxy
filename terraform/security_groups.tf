# ---------- Proxy (public-facing) ----------

resource "aws_security_group" "proxy" {
  name        = "${var.project_name}-proxy-sg"
  description = "Public-facing Nginx reverse proxy"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-proxy-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "proxy_http" {
  security_group_id = aws_security_group.proxy.id
  description       = "HTTP from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# The proxy needs outbound access to install Nginx, reach the app,
# and talk to Systems Manager.
resource "aws_vpc_security_group_egress_rule" "proxy_all" {
  security_group_id = aws_security_group.proxy.id
  description       = "All outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------- App (private) ----------

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Backend app, reachable only from the proxy"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# The source is the proxy's security group, not a CIDR range. Any instance
# that carries the proxy SG is allowed in; nothing else is, even inside the VPC.
resource "aws_vpc_security_group_ingress_rule" "app_from_proxy" {
  security_group_id            = aws_security_group.app.id
  description                  = "App port from the proxy only"
  referenced_security_group_id = aws_security_group.proxy.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

# No egress rule for the app. Security groups are stateful, so responses to
# allowed inbound requests go back out automatically, and the app never
# initiates outbound connections.