## Cross-Account Orchestration via AWS Systems Manager (SSM)

### Scenario

This setup involves two AWS accounts:

- **Account A**: Hosts the orchestration platform (e.g., Ansible, Octopus, or Chef)
- **Account B**: Hosts EC2 instances in private subnets, where deployments need to be executed.

The goal is to execute remote commands on EC2 instances in Account B from Account A without using SSH or public access. This is accomplished using AWS Systems Manager (SSM) and IAM role assumption.

---

### Design Overview

- EC2 instances in Account B are placed in private subnets, with no public IPs.
- Systems Manager (SSM) Agent is installed and active on the EC2 instances.
- VPC Interface Endpoints are created in Account B for SSM-related services.
- IAM role assumption is enabled from Account A to allow triggering SSM commands on Account B's EC2s.

---

### IAM Role Configuration

#### Account B: EC2 IAM Role with Trust for Account A

```hcl
resource "aws_iam_role" "ssm_ec2_role" {
  name = "SSMManagedEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::<ACCOUNT_A_ID>:root"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core_attach" {
  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

#### Account A: IAM Role and Policy to Assume Role in Account B

```hcl
resource "aws_iam_role" "orchestration_role" {
  name = "OrchestrationRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "assume_cross_account" {
  name = "AssumeAccountBSSM"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Resource = "arn:aws:iam::<ACCOUNT_B_ID>:role/SSMManagedEC2Role"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_assume_policy" {
  role       = aws_iam_role.orchestration_role.name
  policy_arn = aws_iam_policy.assume_cross_account.arn
}
```

---

### VPC Endpoint Configuration (Account B)

VPC Interface Endpoints are used to enable private connectivity to SSM services:

```hcl
locals {
  ssm_services = [
    "ssm",
    "ec2messages",
    "ssmmessages"
  ]
}

resource "aws_vpc_endpoint" "ssm_endpoints" {
  for_each = toset(local.ssm_services)

  vpc_id              = <vpc_id>
  subnet_ids          = <private_subnet_ids>
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [<endpoint_sg_id>]
}
```

Ensure the security group allows HTTPS (port 443) from the EC2 subnet.

---

### Orchestration Command via SSM

Once the IAM role is assumed, a command can be triggered from Account A to install and configure software:

```bash
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --instance-ids <ec2-instance-id> \
  --parameters 'commands=["sudo apt update -y", "sudo apt install nginx -y", "systemctl enable nginx", "systemctl start nginx"]' \
  --region <region> \
  --comment "Run configuration via orchestrator" \
  --output text
```

This demonstrates software provisioning from the orchestrator into the private EC2 instance without SSH or public access.

---

### Networking Requirements

- EC2 instances must be launched in private subnets.
- Outbound HTTPS access must be allowed (via VPC endpoints, not NAT).
- VPC interface endpoints must exist for `ssm`, `ec2messages`, and `ssmmessages`.
- Endpoint security group should allow inbound 443 from EC2 CIDRs.

---

### Security Considerations

- Limit IAM trust policies to specific AWS account IDs.
- Apply least privilege to `ssm:SendCommand` actions.
- Enable CloudTrail logging to track cross-account API activity.
- Monitor EC2 and SSM logs in CloudWatch.

---

### Cost Optimization Note

We explicitly avoid the use of NAT Gateways in this design to reduce operational costs. NAT Gateways are priced per hour and per GB of data transferred. By using VPC Interface Endpoints, the solution maintains private connectivity to AWS APIs while offering a more cost-effective and secure setup suitable for production environments.
