# 1) VPC 생성
resource "aws_vpc" "jch_vpc" {
  cidr_block           = "10.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "jch_vpc"
  }

}


# 2) public-subnet 생성 1,2
resource "aws_subnet" "jch_public_subnet1" {
  vpc_id                  = aws_vpc.jch_vpc.id
  cidr_block              = "10.16.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "jch-public1"
  }
}

resource "aws_subnet" "jch_public_subnet2" {
  vpc_id                  = aws_vpc.jch_vpc.id
  cidr_block              = "10.16.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2c"

  tags = {
    Name = "jch-public2"
  }
}
# internet gateway 생성
resource "aws_internet_gateway" "jch_internet_gateway" {
  vpc_id = aws_vpc.jch_vpc.id

  tags = {
    Name = "jch-igw"
  }
}
# Elastic Ip 생성
resource "aws_eip" "NAT-eip" {
  vpc = true
  tags = {
    Name = "NAT-eip"
  }
}

# NAT 게이트웨이 생성
resource "aws_nat_gateway" "myNAT" {
  allocation_id = aws_eip.NAT-eip.id
  subnet_id     = aws_subnet.jch_public_subnet2.id

  tags = {
    Name = "myNAT"
  }
}

# public-route 생성
resource "aws_route_table" "jch_public_rt" {
  vpc_id = aws_vpc.jch_vpc.id


  tags = {
    Name = "jch_public_rt"
  }
}
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.jch_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.jch_internet_gateway.id
}
resource "aws_route_table_association" "jch_public_assoc1" {
  subnet_id      = aws_subnet.jch_public_subnet1.id
  route_table_id = aws_route_table.jch_public_rt.id
}

resource "aws_route_table_association" "jch_public_assoc2" {
  subnet_id      = aws_subnet.jch_public_subnet2.id
  route_table_id = aws_route_table.jch_public_rt.id
}

# private-route 생성 1,2,3,4
resource "aws_route_table" "jch_private_rt" {
  vpc_id = aws_vpc.jch_vpc.id

  tags = {
    Name = "jch_private_rt"
  }
}


resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.jch_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.myNAT.id
}


resource "aws_route_table_association" "jch_private_assoc1" {
  subnet_id      = aws_subnet.jch_private_subnet1.id
  route_table_id = aws_route_table.jch_private_rt.id
}

resource "aws_route_table_association" "jch_private_assoc2" {
  subnet_id      = aws_subnet.jch_private_subnet2.id
  route_table_id = aws_route_table.jch_private_rt.id
}

resource "aws_route_table_association" "jch_private_assoc3" {
  subnet_id      = aws_subnet.jch_private_subnet3.id
  route_table_id = aws_route_table.jch_private_rt.id
}

resource "aws_route_table_association" "jch_private_assoc4" {
  subnet_id      = aws_subnet.jch_private_subnet4.id
  route_table_id = aws_route_table.jch_private_rt.id
}

# private subnet 1,2,3,4 생성
resource "aws_subnet" "jch_private_subnet1" {
  vpc_id            = aws_vpc.jch_vpc.id
  cidr_block        = "10.16.3.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "jch-private1"
  }
}

resource "aws_subnet" "jch_private_subnet2" {
  vpc_id            = aws_vpc.jch_vpc.id
  cidr_block        = "10.16.4.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "jch-private2"
  }
}

resource "aws_subnet" "jch_private_subnet3" {
  vpc_id            = aws_vpc.jch_vpc.id
  cidr_block        = "10.16.5.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "jch-private3"
  }
}

resource "aws_subnet" "jch_private_subnet4" {
  vpc_id            = aws_vpc.jch_vpc.id
  cidr_block        = "10.16.6.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "jch-private4"
  }
}
