variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1" # Optional default value
}

variable "availability_zone" {
  type = string
  default = "us-east-1a"
  description = "Availability zone for the public subnet"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the shared VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "CIDR block for the shared Public Subnet"
  default     = "10.0.1.0/24"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
  default     = "ami-0866a3c8686eaeeba"  # Ubuntu 20.04 in us-east-1; change for your region/OS preference

}

variable "encapsulation" {
  description = "The Encapsulatin method used by Calico"
  type        = string
  default     = "IPIP"
}


variable "instance_type" {
  default = "t3.medium"
}



variable "clusters" {
  type = list(object({
    cluster_name            = string
    private_subnet_cidr_block = string
    controlplane_private_ip = string
    pod_subnet              = string
    worker_count            = number
    service_cidr            = string
    asn                       = number
    bgp_peers                 = list(object({
      target_cluster   = string
      }))
  }))
}
