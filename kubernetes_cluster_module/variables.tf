variable "region" {
  description = "AWS region for the Kubernetes cluster resources"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the resources"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "key_name" {
  description = "Name of the SSH key pair to use for instances"
  type        = string
}

variable "private_key" {
  description = "Private key content for SSH access"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet"
  type        = string
}

variable "public_subnet_cidr_block" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr_block" {
  description = "CIDR block for the private subnet"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the Kubernetes nodes"
  type        = string
}

variable "controlplane_private_ip" {
  description = "Private IP of the control plane"
  type        = string
}

variable "pod_subnet" {
  description = "CIDR block for the pod network"
  type        = string
}

variable "service_cidr" {
  description = "CIDR block for the Kubernetes Services"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the Kubernetes cluster"
  type        = string
}

variable "igw_id" {
  description = "Internet Gateway ID for the VPC"
  type        = string
}

variable "private_route_table_id" {
  description = "Route table ID for the private subnet"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile for EC2 instances"
  type        = string
}

variable "encapsulation" {
  description = "The Encapsulatin method used by Calico"
  type        = string
}

variable "public_sg_id" {
  description = "The ID of the public security group"
  type        = string
}

variable "bastion_public_dns" {
  description = "Public DNS of the bastion host"
  type        = string
}



variable "copy_files_to_bastion" {
  default = [
    "my_k8s_key.pem"
  ]
}

variable "clusters" {
  description = "List of all clusters for updating /etc/hosts across nodes"
  type = list(object({
    cluster_name        = string
    private_subnet_cidr_block = string
    controlplane_private_ip = string
    pod_subnet              = string
    worker_count            = number
    service_cidr            = string
    asn                       = number
    bgp_peers                 = list(object({
      target_cluster = string
    }))
  }))
}

variable "cluster_details" {
  description = "Preprocessed cluster IPs and hostnames for all clusters"
  type = map(object({
    asn           = number
    service_cidr  = string
    pod_subnet    = string
    control_plane = object({
      ip       = string
      hostname = string
    })
    workers = list(object({
      ip       = string
      hostname = string
    }))
  }))
}

variable "asn" {
  description = "Autonomous System Number for the cluster"
  type        = number
}

variable "bgp_peers" {
  description = "List of BGP peers for the cluster"
  type        = list(object({
    target_cluster = string
    }))
}
