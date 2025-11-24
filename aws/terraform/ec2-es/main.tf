provider "aws" {
  profile = "aws-mmi-drian"
  region  = var.aws_region
}

# Data source for AMI (Ubuntu 24.04)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source for VPC
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Data source for subnet - use subnet_id if provided, otherwise lookup by name
data "aws_subnet" "main" {
  count = var.subnet_id != "" ? 0 : 1
  
  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Get subnet directly by ID if subnet_id is provided
data "aws_subnet" "main_by_id" {
  count = var.subnet_id != "" ? 1 : 0
  id    = var.subnet_id
}

locals {
  subnet_id = var.subnet_id != "" ? data.aws_subnet.main_by_id[0].id : data.aws_subnet.main[0].id
  
  # Use user data script directly without template variables
  user_data = var.enable_user_data ? file("${path.module}/user_data.sh") : ""
}

# Data source for security groups
data "aws_security_groups" "main" {
  filter {
    name   = "group-id"
    values = var.security_group_ids
  }
}

# Data source for key pair (verify it exists)
data "aws_key_pair" "main" {
  key_name = var.key_name
}

# EC2 Instances (es7-internal to es10-internal)
resource "aws_instance" "es_internal" {
  count = var.instance_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = local.subnet_id
  user_data     = local.user_data

  vpc_security_group_ids = var.security_group_ids

  # Root volume (30GB) - mounted as root filesystem (/)
  # Note: On NVMe instances, device ordering (nvme0n1 vs nvme1n1) is NOT guaranteed
  # The user_data script dynamically identifies volumes by size and mount status
  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size  # 30GB
    iops        = var.root_volume_type == "gp3" ? var.root_volume_iops : null
    throughput  = var.root_volume_type == "gp3" ? var.root_volume_throughput : null
    encrypted   = var.root_volume_encrypted
    tags = {
      Name = "${var.instance_name_prefix}${count.index + var.start_index}-root"
    }
  }

  # Additional EBS volume (1000GB) - attached as /dev/sdb
  # Note: On NVMe instances, this may appear as nvme0n1 OR nvme1n1 depending on enumeration order
  # The user_data script dynamically finds this volume by size (~1000GB) and absence of partitions
  ebs_block_device {
    device_name = var.additional_volume_device  # /dev/sdb (NVMe device name is unpredictable)
    volume_type = var.additional_volume_type
    volume_size = var.additional_volume_size  # 1000GB
    iops        = var.additional_volume_type == "gp3" ? var.additional_volume_iops : null
    throughput  = var.additional_volume_type == "gp3" ? var.additional_volume_throughput : null
    encrypted   = var.additional_volume_encrypted
    tags = {
      Name = "${var.instance_name_prefix}${count.index + var.start_index}-data"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.instance_name_prefix}${count.index + var.start_index}-internal"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
