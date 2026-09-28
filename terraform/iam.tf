# Lets you open a shell on the proxy through Systems Manager Session Manager,
# so there is no SSH port open and no key pair to manage.

resource "aws_iam_role" "proxy" {
  name = "${var.project_name}-proxy-role"

  # Trust policy: who may assume this role (the EC2 service).
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Permissions policy: what the role can do once assumed (AWS-managed).
resource "aws_iam_role_policy_attachment" "proxy_ssm" {
  role       = aws_iam_role.proxy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 can't use a role directly; it needs an instance profile wrapping it.
resource "aws_iam_instance_profile" "proxy" {
  name = "${var.project_name}-proxy-profile"
  role = aws_iam_role.proxy.name
}