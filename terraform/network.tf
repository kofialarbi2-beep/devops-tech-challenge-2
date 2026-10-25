# Create our AWS VPC
resource "aws_vpc" "tech2_vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "tech2-vpc"
    Project = "TechChallenge2"
  }
}

# Public subnet in Availability Zone A
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.tech2_vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "tech2-public-a"
    "kubernetes.io/role/elb" = "1"
  }
}

# Public subnet in Availability Zone B
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.tech2_vpc.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "tech2-public-b"
    "kubernetes.io/role/elb" = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "tech2_igw" {
  vpc_id = aws_vpc.tech2_vpc.id

  tags = {
    Name = "tech2-igw"
  }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.tech2_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tech2_igw.id
  }

  tags = {
    Name = "tech2-public-rt"
  }
}

# Associate public subnets with route table
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}