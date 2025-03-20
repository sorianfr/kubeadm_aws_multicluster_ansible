provider "aws" {
  region = var.region
}

# Preprocess the IPs and hostnames for each cluster
locals {
  cluster_details = {
    for cluster in var.clusters :
    cluster.cluster_name => {
      asn           = cluster.asn      
      service_cidr  = cluster.service_cidr
      pod_subnet    = cluster.pod_subnet
      control_plane = {
        ip       = cluster.controlplane_private_ip
        hostname = "${cluster.cluster_name}controlplane"
      }
      workers = [
        for i in range(0, cluster.worker_count) : {
          ip       = cidrhost(cluster.private_subnet_cidr_block, 11 + i)
          hostname = "${cluster.cluster_name}worker${i + 1}"
        }
      ]
    }
  }
}


# Generate a TLS private key
resource "tls_private_key" "k8s_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Key Pair
resource "aws_key_pair" "k8s_key_pair" {
  key_name   = "my_k8s_key"
  public_key = tls_private_key.k8s_key_pair.public_key_openssh
}

# Save the private key locally
resource "local_file" "save_private_key" {
  filename = "${path.module}/my_k8s_key.pem"
  content  = tls_private_key.k8s_key_pair.private_key_pem
  file_permission = "0600"

}

# Output the private key (for reference or debugging)
output "k8s_private_key" {
  value     = tls_private_key.k8s_key_pair.private_key_pem
  sensitive = true
}


# VPC for All Clusters
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main_vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = {
    Name = "public_subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_igw"
  }
}


# Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IP for Shared NAT Gateway
resource "aws_eip" "shared_nat_eip" {

  tags = {
    Name = "shared_nat_eip"
  }
}

# Shared NAT Gateway
resource "aws_nat_gateway" "shared_nat_gw" {
  allocation_id = aws_eip.shared_nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "shared_nat_gw"
  }

  depends_on = [aws_eip.shared_nat_eip]
}

# Shared Private Route Table
resource "aws_route_table" "shared_private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.shared_nat_gw.id
  }

  tags = {
    Name = "shared_private_rt"
  }
}



# Shared Bastion Host (uses public subnet)
resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name      = aws_key_pair.k8s_key_pair.key_name

  tags = {
    Name = "shared_bastion"
  }
}

# Shared Bastion Host Security Group
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust for production environments
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion_sg"
  }
}

# IAM Role for EC2 instances to access S3 and other resources
resource "aws_iam_role" "AmazonEBSCSIDriverRole" {
  name = "AmazonEBSCSIDriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
} 
  
# Attach policy to role
resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.AmazonEBSCSIDriverRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
# Create instance profile to be attached to ec2 instances. 
resource "aws_iam_instance_profile" "AmazonEBS_instance_profile" {
  name = "AmazonEBS_instance_profile"
  role = aws_iam_role.AmazonEBSCSIDriverRole.name
}


module "kubernetes_clusters" {
  source = "./kubernetes_cluster_module"
  providers = {
    aws = aws
  }
  # Convert clusters to a map for for_each
  for_each = { for cluster in var.clusters : cluster.cluster_name => cluster }

  # Shared attributes
  clusters                 = var.clusters  # Pass all clusters to the module
  cluster_details          = local.cluster_details # Pass the preprocessed cluster IPs and hostnames
  vpc_id                   = aws_vpc.main_vpc.id  # Pass the VPC ID
  vpc_cidr_block           = var.vpc_cidr_block           # Pass VPC CIDR block
  ami_id                   = var.ami_id                   # Pass AMI ID
  availability_zone        = var.availability_zone
  public_subnet_id         = aws_subnet.public_subnet.id  # Shared public subnet
  igw_id                   = aws_internet_gateway.main_igw.id  # Pass IGW ID
  instance_type            = var.instance_type            # Pass instance type
  public_subnet_cidr_block = var.public_subnet_cidr_block  # Pass public subnet CIDR block
  private_route_table_id   = aws_route_table.shared_private_rt.id  # Pass shared route table
  key_name                 = aws_key_pair.k8s_key_pair.key_name  # Pass key name
  iam_instance_profile     = aws_iam_instance_profile.AmazonEBS_instance_profile.name
  region                   = var.region
  encapsulation            = var.encapsulation
  public_sg_id             = aws_security_group.bastion_sg.id

  bastion_public_dns       = aws_instance.bastion.public_dns

  # Cluster-specific attributes

  cluster_name             = each.value.cluster_name
  private_subnet_cidr_block = each.value.private_subnet_cidr_block
  controlplane_private_ip  = each.value.controlplane_private_ip
  pod_subnet               = each.value.pod_subnet
  service_cidr             = each.value.service_cidr
  
  worker_count             = each.value.worker_count
  asn                      = each.value.asn
  bgp_peers                = each.value.bgp_peers

  # Pass the private key
  private_key              = tls_private_key.k8s_key_pair.private_key_pem

  depends_on = [
    aws_vpc.main_vpc,
    aws_nat_gateway.shared_nat_gw,
    aws_route_table.public_rt,
    aws_instance.bastion
  ]

}







