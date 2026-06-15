# ==============================================================================
# Author: Mazen Monib
# Project: Advanced Database Architecture - Master's Research
# Focus: Distributed Systems, Low-Latency Data Delivery, and Fault Tolerance
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. DB SUBNET GROUP
# Provides the network isolation layer for the database cluster.
# ------------------------------------------------------------------------------
resource "aws_db_subnet_group" "db_subnets" {
  name        = "project-db-subnets"
  description = "Isolated subnets for the database tier"
  
  subnet_ids = [
    aws_subnet.database_a.id,
    aws_subnet.database_b.id
  ]

  tags = {
    Name        = "Project-DB-Subnet-Group"
    Environment = "Production"
    Author      = "Mazen Monib"
  }
}

# ------------------------------------------------------------------------------
# 2. CUSTOM PARAMETER GROUP
# Tunes the PostgreSQL engine for advanced workloads and performance logging.
# ------------------------------------------------------------------------------
resource "aws_db_parameter_group" "postgres_custom" {
  name        = "project-pg-16-custom"
  family      = "postgres16"
  description = "Custom parameter group for advanced distributed workloads"

  # Increase working memory for complex sorts/hashes
  parameter {
    name  = "work_mem"
    value = "16384" 
  }

  # Log queries taking longer than 1 second to assist in query optimization
  parameter {
    name  = "log_min_duration_statement"
    value = "1000" 
  }

  tags = {
    Name   = "Project-PG-Custom-Params"
    Author = "Mazen Monib"
  }
}

# ------------------------------------------------------------------------------
# 3. PRIMARY DATABASE (MASTER)
# The core transactional engine. Configured for Multi-AZ synchronous replication.
# ------------------------------------------------------------------------------
resource "aws_db_instance" "postgres" {
  identifier             = "project-postgres-primary"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20

  username               = var.db_username
  password               = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  parameter_group_name   = aws_db_parameter_group.postgres_custom.name

  # High Availability & Fault Tolerance
  multi_az               = true
  publicly_accessible    = false
  skip_final_snapshot    = true

  # Required: Automated backups must be enabled to support Read Replicas
  backup_retention_period = 1

  tags = {
    Name   = "Postgres-Primary-Master"
    Role   = "Transactional-Write-Engine"
    Author = "Mazen Monib"
  }
}

# ------------------------------------------------------------------------------
# 4. READ REPLICA
# Asynchronous replica to offload read traffic and reduce latency.
# ------------------------------------------------------------------------------
resource "aws_db_instance" "postgres_replica" {
  identifier             = "project-postgres-replica"
  
  # Inherits storage, credentials, and engine from the source DB
  replicate_source_db    = aws_db_instance.postgres.identifier
  instance_class         = "db.t3.micro"
  
  # Pinned to a specific AZ to test cross-AZ latency paths
  availability_zone      = "us-east-1b"

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false 

  tags = {
    Name   = "Postgres-Read-Replica"
    Role   = "Low-Latency-Read-Engine"
    Author = "Mazen Monib"
  }
}