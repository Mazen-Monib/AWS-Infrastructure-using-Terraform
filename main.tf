# ==============================================================================
# Author: Mazen Monib
# Project: Advanced Database Architecture - Master's Research
# Focus: Distributed Systems, Low-Latency Data Delivery, and Fault Tolerance
# Component: Core Networking & Identity Access Management (IAM) Baseline
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. VIRTUAL PRIVATE CLOUD (VPC)
# Defines the isolated network boundary for the entire distributed architecture.
# ------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "Project-VPC"
    Environment = "Production"
    Author      = "Mazen Monib"
  }
}

# ------------------------------------------------------------------------------
# 2. INTERNET GATEWAY (IGW)
# Allows public subnets to communicate outbound to the internet and receive HTTP traffic.
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name   = "Project-Internet-Gateway"
    Author = "Mazen Monib"
  }
}

# ------------------------------------------------------------------------------
# 3. SUBNET ARCHITECTURE (Highly Available - Distributed Across 2 AZs)
# ------------------------------------------------------------------------------

# --- Public Web/ALB Subnets ---
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name   = "Subnet-Public-1A"
    Tier   = "Public-ALB"
    Author = "Mazen Monib"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name   = "Subnet-Public-1B"
    Tier   = "Public-ALB"
    Author = "Mazen Monib"
  }
}

# --- Private Compute Subnets (Application Servers) ---
resource "aws_subnet" "private_compute_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name   = "Subnet-Private-Compute-1A"
    Tier   = "Private-App"
    Author = "Mazen Monib"
  }
}

resource "aws_subnet" "private_compute_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name   = "Subnet-Private-Compute-1B"
    Tier   = "Private-App"
    Author = "Mazen Monib"
  }
}

# --- Private Isolated Database Subnets ---
resource "aws_subnet" "database_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name   = "Subnet-Isolated-DB-1A"
    Tier   = "Isolated-Database"
    Author = "Mazen Monib"
  }
}

resource "aws_subnet" "database_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name   = "Subnet-Isolated-DB-1B"
    Tier   = "Isolated-Database"
    Author = "Mazen Monib"
  }
}

# ------------------------------------------------------------------------------
# 4. NAT GATEWAYS (Redundant Multi-AZ Design for Fault Tolerance)
# Ensures app servers can pull security patches out to the internet without public exposure.
# ------------------------------------------------------------------------------
resource "aws_eip" "nat_a" {
  domain = "vpc"
  tags   = { Name = "EIP-NAT-A", Author = "Mazen Monib" }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"
  tags   = { Name = "EIP-NAT-B", Author = "Mazen Monib" }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.igw]

  tags = { Name = "NAT-Gateway-AZ-A", Author = "Mazen Monib" }
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id
  depends_on    = [aws_internet_gateway.igw]

  tags = { Name = "NAT-Gateway-AZ-B", Author = "Mazen Monib" }
}

# ------------------------------------------------------------------------------
# 5. ROUTE TABLES & ROUTE TABLE ATTACHMENTS
# Explicit routing maps for deterministic traffic patterns.
# ------------------------------------------------------------------------------

# --- Public Route Table ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "Public-Route-Table", Author = "Mazen Monib" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# --- Private Route Tables (Pointed to local NAT Gateways per AZ) ---
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }
  tags = { Name = "Private-Route-Table-1A", Author = "Mazen Monib" }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }
  tags = { Name = "Private-Route-Table-1B", Author = "Mazen Monib" }
}

resource "aws_route_table_association" "private_compute_a" {
  subnet_id      = aws_subnet.private_compute_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_compute_b" {
  subnet_id      = aws_subnet.private_compute_b.id
  route_table_id = aws_route_table.private_b.id
}

# ------------------------------------------------------------------------------
# 6. IDENTITY ACCESS MANAGEMENT (IAM) Baseline
# Grants compute instances secure, keyless access to manage connections via AWS SSM.
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "Project-EC2-SSM-Execution-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name   = "EC2-SSM-Role"
    Author = "Mazen Monib"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "Project-EC2-Instance-Profile"
  role = aws_iam_role.ec2_role.name
}