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
# vpc 에서 데이터 끌어오기
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../vpc/terraform.tfstate"
  }
}
# db에서 데이터 끌어오기
data "terraform_remote_state" "db" {
  backend = "local"

  config = {
    path = "../rds/terraform.tfstate"
  }
}

# 보안그룹 - instance
resource "aws_security_group" "SG_instance" {
  name        = "SG_instance"
  description = "Allow HTTP(80/tcp, 8080/tcp), ssh(22/tcp), DB(3306/tcp)"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "Allow HTTP(80)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "Allow HTTPs(8080)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ssh(22)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
    Name = "SG_instance"
  }
}

# bastion-인스턴스 생성
resource "aws_instance" "bastion-host" {
  ami           = "ami-035da6a0773842f64" # amazon linux2
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.SG_instance.id]
  subnet_id              = data.terraform_remote_state.vpc.outputs.jch_public_subnet1

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "bastion-host"
  }
}

/*
# test-인스턴스1,2 생성
resource "aws_instance" "ec2_private_web1" {
  ami           = "ami-0ec6da6a8ef69e03f" # Amazon Linux 2023
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web_instanceSG.id]
  subnet_id              = aws_subnet.jch_private_subnet1.id

  root_block_device {
    volume_size = 10
  }

  user_data                   = <<-EOF
  #!/bin/bash
  hostname EC2-1
  echo "<h1>CloudNet@ EC2-1 Web Server</h1>" > /var/www/html/index.html
  EOF
  user_data_replace_on_change = true

  tags = {
    Name = "ec2_private_web1"
  }
}

resource "aws_instance" "ec2_private_web2" {
  ami           = "ami-0ec6da6a8ef69e03f"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web_instanceSG.id]
  subnet_id              = aws_subnet.jch_private_subnet2.id

  root_block_device {
    volume_size = 10
  }

  user_data                   = <<-EOF
  #!/bin/bash
  hostname EC2-2
  echo "<h1>CloudNet@ EC2-2 Web Server</h1>" > /var/www/html/index.html
  EOF
  user_data_replace_on_change = true

  tags = {
    Name = "ec2_private_web2"
  }
}
*/
# 내부 instance에 접근하기위한 key 생성
resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2_key"
  public_key = file("./testPubkey.pub")
}

# Launch Configuration 생성
resource "aws_launch_configuration" "myLaunchCon" {
  image_id        = "ami-0c39b49d2169745ea" # php 등을 설치해둔 이미지
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.SG_instance.id]
  # 접속을 위한 키 이름
  key_name = aws_key_pair.ec2_key.key_name


  user_data = templatefile("userdata.sh", {
    end_point_name = data.terraform_remote_state.db.outputs.DB_dns
    user_name      = data.terraform_remote_state.db.outputs.DB_user
    user_password  = data.terraform_remote_state.db.outputs.DB_password
  })


  /*
  user_data = <<-EOF
  #!/bin/bash
  sudo -i
  sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
  sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
  systemctl restart sshd
  echo 'qwe123' | passwd --stdin root 
  
  EOF
*/
  #user_data_replace_on_change = true
  lifecycle {
    create_before_destroy = true
  }
}

# auto scaling group 생성
resource "aws_autoscaling_group" "Myautoscaling" {
  launch_configuration = aws_launch_configuration.myLaunchCon.id
  vpc_zone_identifier = [
    data.terraform_remote_state.vpc.outputs.jch_private_subnet1,
    data.terraform_remote_state.vpc.outputs.jch_private_subnet2
  ]

  target_group_arns = [aws_lb_target_group.ALB-TG.arn]
  health_check_type = "ELB"

  max_size = 5
  min_size = 2

  tag {
    key                 = "Name"
    value               = "myASG"
    propagate_at_launch = true
  }
}

# Tagret Group 생성
resource "aws_lb_target_group" "ALB-TG" {
  name     = "myALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id

}

/*
resource "aws_lb_target_group_attachment" "target_group_asso" {
  target_group_arn = aws_lb_target_group.ALB-TG.arn
  target_id        = aws_autoscaling_group.MyASG.id
  port             = 80
}


resource "aws_lb_target_group_attachment" "target_group_asso2" {
  target_group_arn = aws_lb_target_group.ALB-TG.arn
  target_id        = aws_instance.ec2_private_web2.id
  port             = 80
}
*/

# 보안그룹 - ALB
resource "aws_security_group" "SG_alb" {
  name        = "WEBSG"
  description = "Allow HTTP(80/tcp, 8080/tcp), ssh(22/tcp), DB(3306/tcp)"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "Allow HTTP(80)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPs(8080)"
    from_port   = 8080
    to_port     = 8080
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
    Name = "SG_alb"
  }
}

# ALB 생성
resource "aws_lb" "ALB" {
  name               = "myALB"
  load_balancer_type = "application"
  subnets = [
    data.terraform_remote_state.vpc.outputs.jch_public_subnet1,
    data.terraform_remote_state.vpc.outputs.jch_public_subnet2
  ]
  security_groups = [aws_security_group.SG_alb.id]

}

# ALB Listner 생성
resource "aws_lb_listener" "ALB-Listener" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}
# ALB Listener rule 생성
resource "aws_lb_listener_rule" "ALB-Listener-Rule" {
  listener_arn = aws_lb_listener.ALB-Listener.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ALB-TG.arn
  }
}
# lb에대한 output
output "lb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.ALB.dns_name
}