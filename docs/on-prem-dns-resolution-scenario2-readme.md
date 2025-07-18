# DNS Resolution from AWS to On-Premises Domain (`abc.org`)

## Scenario Overview

You have multiple Virtual Private Clouds (VPCs) across various regions in **Account B**, running applications on Amazon Elastic Kubernetes Service (EKS) or Amazon EC2. These applications need to resolve and connect to **on-premises services** hosted under the internal domain `abc.org`.

The on-premises DNS server(s) must be reachable via **AWS Direct Connect** using a **Customer Gateway**, **Virtual Private Gateway**, and **private virtual interface**. DNS resolution is performed using **Amazon Route 53 Resolver**.

---

## Solution Architecture

1. Use **Route 53 Resolver forwarding rules** to forward queries for `abc.org` to the on-premises DNS servers.
2. Deploy a **Route 53 outbound resolver endpoint** inside a dedicated DNS VPC Gateway in Account B.
3. Set up **AWS Direct Connect** between the DNS VPC Gateway and the on-premises DNS server using a virtual private gateway, private virtual interface, and customer gateway.
4. Associate resolver rules with all required VPCs hosting workloads.
5. (Optional) Set up **inbound resolver endpoints** for reverse DNS resolution from on-premises to AWS.

---

## ⚙️ Step-by-Step Setup with AWS CLI

### 1️. Set Up Direct Connect Gateway and Private Virtual Interface

Ensure you have an existing AWS Direct Connect connection provisioned.

```bash
aws directconnect create-direct-connect-gateway \
  --direct-connect-gateway-name dc-gw-to-onprem \
  --amazon-side-asn 64512

aws directconnect create-private-virtual-interface \
  --connection-id dxcon-xxxxx \
  --new-private-virtual-interface file://vif-config.json
```

> The JSON file should include BGP configuration and peer IP addresses for the on-premises router.

### 2️. Create a Route 53 Resolver Rule for `abc.org`

```bash
aws route53resolver create-resolver-rule \
  --creator-request-id "abc-org-forward-rule-001" \
  --rule-type FORWARD \
  --name "Forward-abc-org" \
  --domain-name "abc.org" \
  --rule-action FORWARD \
  --resolver-endpoint-id rslvr-out-xxxxx \
  --target-ips Ip="10.10.10.2",Port="53" \
  --region us-east-1
```

### 3️. Associate the Resolver Rule with Workload VPCs

```bash
aws route53resolver associate-resolver-rule \
  --resolver-rule-id rslvr-rr-xxxxx \
  --vpc-id vpc-xxxxx \
  --name "Associate-abc-org-rule" \
  --region us-east-1
```

### 4️. Create Outbound Resolver Endpoint in the DNS VPC Gateway

```bash
aws route53resolver create-resolver-endpoint \
  --creator-request-id "outbound-endpoint-001" \
  --direction OUTBOUND \
  --name "outbound-to-onprem" \
  --security-group-ids sg-xxxxx \
  --ip-addresses SubnetId=subnet-xxxxx,Ip=10.20.1.10 \
  --region us-east-1
```

> Make sure that the security group allows DNS traffic on TCP and UDP port 53.

---

## Verification & Testing

From a private Amazon EC2 instance in a workload VPC:

```bash
dig abc.org
nslookup abc.org
```

Verify that the returned IP address matches the on-premises DNS record.

---

## Security Considerations

- Only allow DNS traffic to trusted IP addresses (on-premises DNS server)
- Use security groups and network access control lists (NACLs) to limit access
- Enable Amazon Route 53 Resolver query logging to Amazon CloudWatch for auditing

```bash
aws route53resolver put-resolver-query-log-config-policy \
  --arn arn:aws:route53resolver:us-east-1:123456789012:resolver-query-log-config/rqlc-xxxxx \
  --policy file://query-log-policy.json
```

---

## Monitoring and Troubleshooting

### Monitoring

- Enable Amazon CloudWatch Logs for Route 53 Resolver
- Monitor AWS Direct Connect virtual interface metrics
- Use Amazon VPC Flow Logs to trace DNS traffic

### Troubleshooting

- Confirm network connectivity between the outbound resolver and on-premises DNS server
- Use tools like `dig`, `nslookup`, or `tcpdump`
- Verify resolver rule associations and endpoint status

## Summary

This setup enables DNS resolution from AWS-hosted applications to on-premises domains (`abc.org`) using Amazon Route 53 Resolver forwarding rules and hybrid connectivity through AWS Direct Connect. It uses a centralized VPC gateway for resolver forwarding and ensures secure, scalable, and low-latency name resolution across cloud and on-premises environments.

