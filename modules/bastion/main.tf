# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion subnet (dedicated for bastion host)
resource "aws_subnet" "bastion" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.bastion_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-bastion-subnet"
    Type = "Bastion"
  }
}

# Route table association for bastion subnet
resource "aws_route_table_association" "bastion" {
  subnet_id      = aws_subnet.bastion.id
  route_table_id = var.public_route_table_id
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name_prefix = "${var.name_prefix}-bastion-sg"
  vpc_id      = var.vpc_id
  description = "Security group for bastion host"

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-bastion-sg"
  }
}

# IAM Role for Bastion Host
resource "aws_iam_role" "bastion" {
  name = "${var.name_prefix}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-bastion-role"
  }
}

# Attach AdministratorAccess policy to the role
resource "aws_iam_role_policy_attachment" "bastion_admin" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Instance Profile for the role
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name_prefix}-bastion-profile"
  role = aws_iam_role.bastion.name

  tags = {
    Name = "${var.name_prefix}-bastion-profile"
  }
}

# User data script to install eksctl
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    region = var.region
  }))
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = aws_subnet.bastion.id
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  user_data = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  tags = {
    Name = "${var.name_prefix}-bastion-host"
    Type = "Bastion"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for Bastion Host
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name = "${var.name_prefix}-bastion-eip"
  }

  depends_on = [aws_instance.bastion]
}
