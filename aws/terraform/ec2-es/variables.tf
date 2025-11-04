variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_name_prefix" {
  description = "Prefix for instance names (e.g., 'es')"
  type        = string
  default     = "es"
}

variable "start_index" {
  description = "Starting number for instance naming (e.g., 7 for es7)"
  type        = number
  default     = 8
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 3
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.xlarge"
}

variable "vpc_name" {
  description = "Name tag of the VPC"
  type        = string
  default     = "mmi-vpc"
}

variable "subnet_id" {
  description = "Subnet ID (if provided, will use this instead of subnet_name)"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Name tag of the subnet (used if subnet_id is not provided)"
  type        = string
  default     = "mmi-vpc-public-ap-southeast-1a"
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
  default = [
    "sg-0cc4c0cd3978e4eeb", # allow-ssh-from-mmi-sg
    "sg-0c5935e3fde64dcf2", # private-public-connection-sg
    "sg-04faac610809d79a8"  # allow_es_connection
  ]
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
  default     = "terraform_key_pair"
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "root_volume_iops" {
  description = "Root volume IOPS (for gp3)"
  type        = number
  default     = 3000
}

variable "root_volume_throughput" {
  description = "Root volume throughput in MB/s (for gp3)"
  type        = number
  default     = 125
}

variable "root_volume_encrypted" {
  description = "Whether to encrypt root volume"
  type        = bool
  default     = false
}

variable "additional_volume_device" {
  description = "Device name for additional EBS volume"
  type        = string
  default     = "/dev/sdb"
}

variable "additional_volume_type" {
  description = "Additional volume type"
  type        = string
  default     = "gp3"
}

variable "additional_volume_size" {
  description = "Additional volume size in GB"
  type        = number
  default     = 1000
}

variable "additional_volume_iops" {
  description = "Additional volume IOPS (for gp3)"
  type        = number
  default     = 3000
}

variable "additional_volume_throughput" {
  description = "Additional volume throughput in MB/s (for gp3)"
  type        = number
  default     = 125
}

variable "additional_volume_encrypted" {
  description = "Whether to encrypt additional volume"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "test"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    company     = "Media Meter Inc"
    environment = "test"
    terraform   = "true"
  }
}

variable "elasticsearch_version" {
  description = "ElasticSearch Docker image version"
  type        = string
  default     = "7.17.7"
}

variable "elasticsearch_cluster_name" {
  description = "ElasticSearch cluster name"
  type        = string
  default     = "mmi-aws-elasticsearch-cluster"
}

variable "elasticsearch_java_opts" {
  description = "ElasticSearch JVM options"
  type        = string
  default     = "-Xms10g -Xmx10g"
}

variable "elasticsearch_seed_hosts" {
  description = "List of seed host IPs for ElasticSearch discovery (comma-separated)"
  type        = string
  default     = "10.0.3.6,10.0.3.7,10.0.3.8,10.0.3.9"  # es6 + es7-es10
}

variable "elasticsearch_initial_master_nodes" {
  description = "List of initial master node IPs (comma-separated)"
  type        = string
  default     = "10.0.3.5,10.0.3.6,10.0.3.7,10.0.3.8,10.0.3.9"  # es6 + es7-es10
}

variable "enable_user_data" {
  description = "Enable user data script for Docker and ElasticSearch setup"
  type        = bool
  default     = true
}
