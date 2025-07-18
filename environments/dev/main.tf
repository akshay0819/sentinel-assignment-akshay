provider "aws" {
  region  = "eu-central-1"
}

module "backend" {
  source      = "../../modules/backend"
  environment = "dev"
  region      = "eu-central-1"
}

module "vpc_gateway" {
  source               = "../../modules/vpc"
  name                 = "vpc-gateway"
  cidr_block           = "10.10.0.0/16"
  private_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
  public_subnet_cidrs  = ["10.10.10.0/24", "10.10.11.0/24"]
  azs                  = ["eu-central-1a", "eu-central-1b"]
  region               = "eu-central-1"
  eks_cluster_name = "eks-gateway"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Environment = "dev"
  }
}

module "vpc_backend" {
  source               = "../../modules/vpc"
  name                 = "vpc-backend"
  cidr_block           = "10.20.0.0/16"
  private_subnet_cidrs = ["10.20.1.0/24", "10.20.2.0/24"]
  public_subnet_cidrs  = ["10.20.10.0/24", "10.20.11.0/24"]
  azs                  = ["eu-central-1a", "eu-central-1b"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true
  region               = "eu-central-1"
  tags = {
    Environment = "dev"
  }
}

module "vpc_peering" {
  source = "../../modules/vpc_peering"
  name   = "gateway-backend"

  vpc_id_requester                         = module.vpc_gateway.vpc_id
  vpc_id_accepter                          = module.vpc_backend.vpc_id
  requester_vpc_cidr                       = module.vpc_gateway.vpc_cidr_block
  accepter_vpc_cidr                        = module.vpc_backend.vpc_cidr_block
  requester_private_subnet_route_table_ids = module.vpc_gateway.private_route_table_ids
  requester_public_subnet_route_table_ids  = module.vpc_gateway.public_route_table_ids
  accepter_private_subnet_route_table_ids  = module.vpc_backend.private_route_table_ids

  tags = {
    Environment = "dev"
  }
}

module "eks_gateway" {
  source             = "../../modules/eks"
  name               = "eks-gateway"
  cluster_version    = "1.29"
  vpc_id             = module.vpc_gateway.vpc_id
  private_subnet_ids = module.vpc_gateway.private_subnet_ids
  public_subnet_ids  = module.vpc_gateway.public_subnet_ids
  tags = {
    Environment = "dev"
  }
}

module "eks_backend" {
  source             = "../../modules/eks"
  name               = "eks-backend"
  cluster_version    = "1.29"
  vpc_id             = module.vpc_backend.vpc_id
  private_subnet_ids = module.vpc_backend.private_subnet_ids
  tags = {
    Environment = "dev"
  }
}

resource "aws_security_group_rule" "allow_gateway_to_backend" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = module.eks_backend.cluster_security_group_id
  source_security_group_id = module.eks_gateway.cluster_security_group_id
  description              = "Allow gateway EKS cluster to access backend"
}

resource "aws_security_group_rule" "allow_gateway_to_backend_5678" {
  type                     = "ingress"
  from_port                = 5678
  to_port                  = 5678
  protocol                 = "tcp"
  security_group_id        = module.eks_backend.cluster_security_group_id
  source_security_group_id = module.eks_gateway.cluster_security_group_id
  description              = "Allow gateway EKS cluster to access backend pod directly on port 5678"
}

module "bastion_backend" {
  source        = "../../modules/ec2_ssm_bastion"
  name          = "eks-bastion-backend"
  ami_id        = "ami-01fef3b730849ff89"
  instance_type = "t3.micro"
  subnet_id     = module.vpc_backend.private_subnet_ids[0]
  vpc_id        = module.vpc_backend.vpc_id

  tags = {
    Environment = "dev",
    Name        = "akshay-eks-ssm-bastion-backend"
  }
}

module "bastion_gateway" {
  source        = "../../modules/ec2_ssm_bastion"
  name          = "eks-bastion-gateway"
  ami_id        = "ami-01fef3b730849ff89"
  instance_type = "t3.micro"
  subnet_id     = module.vpc_gateway.private_subnet_ids[0]
  vpc_id        = module.vpc_gateway.vpc_id

  tags = {
    Environment = "dev",
    Name        = "akshay-eks-ssm-bastion-gateway"
  }
}

resource "aws_security_group_rule" "bastion_to_eks_nodes_gateway" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks_gateway.cluster_security_group_id
  source_security_group_id = module.bastion_gateway.bastion_sg_id
  description              = "Allow bastion EC2 to access EKS API server"
}

resource "aws_security_group_rule" "bastion_to_eks_nodes_backend" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks_backend.cluster_security_group_id
  source_security_group_id = module.bastion_backend.bastion_sg_id
  description              = "Allow bastion EC2 to access EKS API server"
}