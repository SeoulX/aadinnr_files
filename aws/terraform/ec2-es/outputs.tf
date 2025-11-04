output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.es_internal[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of the EC2 instances"
  value       = aws_instance.es_internal[*].private_ip
}

output "instance_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.es_internal[*].public_ip
}

output "instance_names" {
  description = "Names of the EC2 instances"
  value       = aws_instance.es_internal[*].tags.Name
}

output "instance_details" {
  description = "Detailed information about all instances"
  value = {
    for idx, instance in aws_instance.es_internal : instance.tags.Name => {
      instance_id    = instance.id
      instance_type  = instance.instance_type
      private_ip     = instance.private_ip
      public_ip      = instance.public_ip
      subnet_id      = instance.subnet_id
      vpc_security_group_ids = instance.vpc_security_group_ids
      availability_zone = instance.availability_zone
    }
  }
}
