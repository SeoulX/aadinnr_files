# EC2 ES Instances Terraform Configuration

This Terraform configuration provisions 4 EC2 instances (es7-internal, es8-internal, es9-internal, es10-internal) with the same configuration as the existing es6-internal instance.

## Configuration Summary

Based on the existing `es6-internal` instance, this configuration creates:

- **4 instances**: es7-internal, es8-internal, es9-internal, es10-internal
- **Instance Type**: t3.xlarge
- **AMI**: Ubuntu 24.04 LTS (auto-detected)
- **VPC**: mmi-vpc (ap-southeast-1a)
- **Security Groups**: 
  - allow-ssh-from-mmi-sg
  - private-public-connection-sg
  - allow_es_connection
- **Key Pair**: terraform_key_pair
- **Root Volume**: 30 GB gp3 (3000 IOPS, 125 MB/s throughput)
- **Data Volume**: 1000 GB gp3 (3000 IOPS, 125 MB/s throughput) on /dev/sdb

## Prerequisites

1. AWS CLI configured with the `aws-mmi-drian` profile
2. Terraform >= 1.0 installed
3. Appropriate AWS permissions to create EC2 instances, volumes, and security groups
4. The key pair `terraform_key_pair` must exist in AWS

## Usage

1. **Initialize Terraform**:
   ```bash
   cd aws/terraform/ec2-es
   terraform init
   ```

2. **Review the plan** (shows what will be created):
   ```bash
   terraform plan
   ```

3. **Apply the configuration** (creates the instances):
   ```bash
   terraform apply
   ```

4. **View outputs** after creation:
   ```bash
   terraform output
   ```

5. **Destroy the resources** (when needed):
   ```bash
   terraform destroy
   ```

## Customization

You can customize the number of instances and starting index by modifying `terraform.tfvars`:

```hcl
start_index    = 7  # Start numbering from 7
instance_count = 4  # Creates 4 instances (es7-es10)
```

To create different instances, change these values:
- `start_index = 11` and `instance_count = 5` would create es11-es15
- `start_index = 1` and `instance_count = 6` would create es1-es6

## Outputs

After deployment, Terraform will output:
- `instance_ids`: List of all instance IDs
- `instance_private_ips`: List of private IP addresses
- `instance_public_ips`: List of public IP addresses
- `instance_names`: List of instance names
- `instance_details`: Detailed information about all instances

## Example Output

```bash
$ terraform output instance_details
{
  "es7-internal" = {
    instance_id = "i-xxxxx"
    instance_type = "t3.xlarge"
    private_ip = "10.0.3.xxx"
    public_ip = "xx.xxx.xxx.xxx"
    ...
  }
  "es8-internal" = { ... }
  ...
}
```

## Notes

- The instances will be created in the same subnet as es6-internal (mmi-vpc-public-ap-southeast-1a)
- All instances use the same security groups, key pair, and volume configuration
- The AMI is automatically detected (latest Ubuntu 24.04 LTS)
- Volumes are not encrypted by default (matching es6-internal configuration)
- Instances are tagged with company, environment, and terraform tags

## Troubleshooting

1. **Verify AWS profile**:
   ```bash
   aws sts get-caller-identity --profile aws-mmi-drian
   ```

2. **Check VPC and subnet exist**:
   ```bash
   aws ec2 describe-vpcs --profile aws-mmi-drian --region ap-southeast-1 --filters "Name=tag:Name,Values=mmi-vpc"
   aws ec2 describe-subnets --profile aws-mmi-drian --region ap-southeast-1 --filters "Name=tag:Name,Values=mmi-vpc-public-ap-southeast-1a"
   ```

3. **Verify key pair exists**:
   ```bash
   aws ec2 describe-key-pairs --profile aws-mmi-drian --region ap-southeast-1 --key-names terraform_key_pair
   ```

4. **Review Terraform state**:
   ```bash
   terraform show
   ```
