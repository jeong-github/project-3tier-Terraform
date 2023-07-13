terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../vpc/terraform.tfstate"
  }
}


# 보안그룹 - db
resource "aws_security_group" "DBSG" {
  name        = "DBSG"
  description = "allow to DB(3306/tcp)"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id


  ingress {
    description = "Allow DB(3306)"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "DBSG"
  }
}

# db subnetgroup 생성
resource "aws_db_subnet_group" "MyDB-Group" {
  name = "dbsubnetgroup"

  subnet_ids = [
    data.terraform_remote_state.vpc.outputs.jch_private_subnet3,
    data.terraform_remote_state.vpc.outputs.jch_private_subnet4
  ]

  tags = {
    Name = "My DB subnet group"
  }
}

/*
resource "aws_db_instance" "MyDB" {
  db_subnet_group_name   = aws_db_subnet_group.MyDB-Group.id
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  name                   = "mydb"
  username               = var.database_user
  password               = var.database_password
  identifier             = "jch-db"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.DBSG.id]
  #multi_az               = true
}
*/

resource "aws_rds_cluster" "MyRDS" {
  db_subnet_group_name   = aws_db_subnet_group.MyDB-Group.id
  cluster_identifier     = "jch-db"
  engine                 = "aurora-mysql"
  engine_version         = "5.7.mysql_aurora.2.11.2"
  availability_zones     = ["ap-northeast-2a", "ap-northeast-2c"]
  database_name          = "mydb"
  master_username        = var.database_user
  master_password        = var.database_password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.DBSG.id]
  port                   = 3306
}

resource "aws_rds_cluster_instance" "MyRDS_instance" {
  count      = 2
  identifier = "jch-db-instance-${count.index}"
  #identifier         = "jch-db-instance-1"
  cluster_identifier = aws_rds_cluster.MyRDS.id
  instance_class     = "db.t3.small"
  engine             = aws_rds_cluster.MyRDS.engine
  engine_version     = aws_rds_cluster.MyRDS.engine_version
}

