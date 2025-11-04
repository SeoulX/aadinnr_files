#!/bin/bash
# Script to verify EC2 instances and check if user data script ran

echo "=== Checking Terraform State ==="
cd "$(dirname "$0")"

if [ -f terraform.tfstate ]; then
    echo "Instances in Terraform state:"
    terraform output instance_names 2>/dev/null || echo "No instances found in state"
    echo ""
    echo "Instance details:"
    terraform output instance_details 2>/dev/null || echo "No instances found in state"
    echo ""
    echo "Private IPs:"
    terraform output instance_private_ips 2>/dev/null || echo "No instances found in state"
    echo ""
    echo "Public IPs:"
    terraform output instance_public_ips 2>/dev/null || echo "No instances found in state"
else
    echo "No Terraform state found. Run 'terraform apply' first."
fi

echo ""
echo "=== Checking AWS Directly ==="
echo "Instances with Name tag matching es*-internal:"
aws ec2 describe-instances \
    --profile aws-mmi-drian \
    --region ap-southeast-1 \
    --filters "Name=tag:Name,Values=es*-internal" \
              "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],InstanceId,State.Name,PrivateIpAddress,PublicIpAddress]' \
    --output table 2>/dev/null || echo "Could not query AWS. Check your AWS credentials."

echo ""
echo "=== To verify user data script ran on an instance ==="
echo "1. SSH into an instance:"
echo "   ssh -i ~/.ssh/terraform_key_pair.pem ubuntu@<PUBLIC_IP>"
echo ""
echo "2. Check user data script logs:"
echo "   tail -f /var/log/cloud-init-output.log"
echo ""
echo "3. Check Docker installation:"
echo "   docker --version"
echo "   docker ps"
echo ""
echo "4. Check ElasticSearch container:"
echo "   docker logs \$(docker ps -q --filter 'ancestor=docker.elastic.co/elasticsearch/elasticsearch:7.17.7')"
echo ""
echo "5. Check setup logs:"
echo "   cat /home/ubuntu/docker-install.log"
echo "   ls -la /mnt/ebs/data"
echo ""
echo "6. Check ElasticSearch health:"
echo "   curl http://localhost:9200/_cluster/health?pretty"

