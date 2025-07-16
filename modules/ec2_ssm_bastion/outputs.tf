output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "bastion_instance_profile" {
  value = aws_iam_instance_profile.ssm_profile.name
}

output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}