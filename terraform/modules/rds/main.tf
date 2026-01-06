# Security group for RDS 
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow access to RDS only from EKS"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow Postgres from EKS"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = var.nodes_sg_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "rds_sg"
    }
  )
}

# RDS subnet group
resource "aws_db_subnet_group" "this" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = var.subnet_ids
  description = "Subnet group for RDS ${var.db_name}"
  tags = merge(
    var.tags,
    {
      Name = "${var.db_name}-subnet-group"
    }
  )
}

# RDS instance
resource "aws_db_instance" "this" {
  identifier                  = var.db_name
  engine                      = var.engine
  engine_version              = var.engine_version
  instance_class              = var.db_instance_class
  allocated_storage           = var.allocated_storage
  name                        = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  iam_database_authentication_enabled = true
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]
  multi_az                    = true
  publicly_accessible         = false
  skip_final_snapshot         = true
  deletion_protection         = false
  
  tags = merge(
    var.tags,
    {
      Name = var.db_name
    }
  )
}


