# ==============================================================================
# Component: Security Groups & Network Access Control
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. LOAD BALANCER SECURITY GROUP
# ------------------------------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Controls public ingress to the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name   = "ALB-Security-Group"
    Author = "Mazen Monib"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_all" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}

# ------------------------------------------------------------------------------
# 2. EC2 COMPUTE SECURITY GROUP
# ------------------------------------------------------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Controls ingress to the web application servers"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name   = "EC2-Security-Group"
    Author = "Mazen Monib"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_http_from_alb" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ec2_egress_all" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}

# ------------------------------------------------------------------------------
# 3. DATABASE SECURITY GROUP
# ------------------------------------------------------------------------------
resource "aws_security_group" "db_sg" {
  name        = "database-security-group"
  description = "Strict isolation for the RDS instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name   = "DB-Security-Group"
    Author = "Mazen Monib"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_ec2" {
  security_group_id            = aws_security_group.db_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "db_egress_all" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}