resource "aws_iam_role" "ssm_ec2_role" {
  name = "akshay-eks-ssm-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "akshay-eks-ssm-ec2-profile"
  role = aws_iam_role.ssm_ec2_role.name
}
resource "aws_iam_role_policy" "s3_read_access" {
  name = "akshay-eks-ssm-s3-read"
  role = aws_iam_role.ssm_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "logs:*"
        ],
        Resource = [
          "arn:aws:s3:::rapyd-sentinel-deploy-artifacts",
          "arn:aws:s3:::rapyd-sentinel-deploy-artifacts/*",
          "arn:aws:logs:eu-central-1:*:log-group:/ssm/*"
        ]
      }
    ]
  })
}

resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids = [aws_security_group.bastion.id]

  associate_public_ip_address = false

  tags = var.tags

    user_data = <<-EOF
    #!/bin/bash
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF

   lifecycle {
    create_before_destroy = true
    ignore_changes = [user_data]
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.name}-bastion-sg"
  description = "Allow internal access to VPC endpoints and EKS"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSM from anywhere"           
    from_port   = 443                                 
    to_port     = 443                                 
    protocol    = "tcp"                              
    cidr_blocks = ["0.0.0.0/0"]                       
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-bastion-sg"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [tags["Name"]] # Optional: avoid recreation on tag name changes
  }
}