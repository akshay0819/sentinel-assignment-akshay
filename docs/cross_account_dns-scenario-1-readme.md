# Cross-Account DNS Resolution with Route 53 Profile and AWS RAM

## Scenario

This setup enables private DNS resolution from applications running in Account B (across multiple VPCs in different regions) to a Private Hosted Zone in Account A, using Route 53 Profiles and AWS Resource Access Manager (RAM).

## Architecture Summary

### AWS Account A (DNS Owner):
- Hosts the Private Hosted Zone for `xyz.com`.
- Creates a Route 53 Profile and associates it with VPC A.
- Shares the Route 53 Profile via AWS RAM.

### AWS Account B (DNS Consumer):
- Accepts the shared Route 53 Profile.
- Associates its VPCs (e.g., VPC-A in eu-west-2, VPC-B in us-east-2) with the profile.

This setup enables all VPCs in Account B to resolve DNS records (e.g., `api.xyz.com`) defined in Account A’s private hosted zone.

## Prerequisites

- AWS Organizations setup between Account A and B.
- RAM sharing enabled.
- Route 53 Resolver endpoints (if required for hybrid or centralized DNS).
- VPC peering or Transit Gateway connectivity if DNS resolution is needed across regions.

## Setup Instructions

### Step 1: In Account A

1. Create Private Hosted Zone:
   ```bash
   aws route53 create-hosted-zone \
     --name xyz.com \
     --vpc VPCRegion=eu-west-1,VPCId=vpc-abc123 \
     --hosted-zone-config Comment="Internal DNS",PrivateZone=true
   ```

2. Create Route 53 Profile:
   ```bash
   aws route53profiles create-profile \
     --name xyz-profile \
     --type PRIVATE
   ```

3. Associate Hosted Zone with Profile:
   ```bash
   aws route53profiles associate-hosted-zone \
     --profile-id xyz-profile-id \
     --hosted-zone-id Z1234567890
   ```

4. Associate Account A VPCs (if needed).

5. Share Profile via RAM:
   ```bash
   aws ram create-resource-share \
     --name "SharedXYZRoute53Profile" \
     --resource-arns arn:aws:route53:::profile/xyz-profile-id \
     --principals arn:aws:iam::<account-b-id>:root
   ```

### Step 2: In Account B

1. Accept RAM Share:
   ```bash
   aws ram accept-resource-share-invitation \
     --resource-share-invitation-arn arn:aws:ram:...
   ```

2. Associate VPCs in Account B:
   ```bash
   aws route53profiles associate-vpc \
     --profile-id xyz-profile-id \
     --vpc-id vpc-b123456 \
     --vpc-region eu-west-2
   ```

## Confirm DNS Resolution

From EC2 or EKS in Account B:
```bash
dig api.xyz.com +short
```

Should return the private IP of the corresponding resource defined in the Hosted Zone in Account A.

You can also check resolver logs:
```bash
cat /etc/resolv.conf
```

## Security Considerations

- RAM shares should be scoped to AWS Organizations or OU to avoid overexposure.
- IAM permissions must be scoped tightly to allow only specific actions.
- If using Route 53 Resolver endpoints across VPCs or on-prem, ensure:
  - DNS Firewall rules are in place if needed.
  - Inbound/outbound endpoints are secured with correct SGs/NACLs.
- Enforce centralized logging of DNS queries via Route 53 query logs or VPC Flow Logs.

## Monitoring and Troubleshooting

### Monitor

- Enable Route 53 Query Logging to CloudWatch.
- Use VPC Flow Logs to verify traffic between VPCs.
- Use CloudTrail to audit RAM and Route 53 Profile operations.

### Troubleshoot

1. DNS Resolution Failure?
   - Check if the VPC is correctly associated with the Route 53 Profile.
   - Ensure no conflicting DNS settings in resolv.conf (for EC2).
   - Confirm that the Private Hosted Zone has correct records.

2. Network Issue?
   - Validate VPC Peering or Transit Gateway setup if needed.
   - Use telnet or nc to confirm connectivity to service IPs.

3. RAM Acceptance?
   - Ensure RAM shares were accepted.
   - Check in AWS RAM Console or use:
     ```bash
     aws ram list-resource-share-invitations
     ```