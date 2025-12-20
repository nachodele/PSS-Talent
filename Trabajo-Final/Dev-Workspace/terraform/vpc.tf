resource "aws_vpc" "pr_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name  = "vpc-pr-${var.pr_id}"
    PR_ID = var.pr_id
  }
}

# SUBNET 1 - AZ us-east-1a
resource "aws_subnet" "pr_subnet_a" {
  vpc_id                  = aws_vpc.pr_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name  = "public-a-pr-${var.pr_id}"
    PR_ID = var.pr_id
  }
}

# SUBNET 2 - AZ us-east-1b  
resource "aws_subnet" "pr_subnet_b" {
  vpc_id                  = aws_vpc.pr_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name  = "public-b-pr-${var.pr_id}"
    PR_ID = var.pr_id
  }
}

# Internet Gateway
resource "aws_internet_gateway" "pr_igw" {
  vpc_id = aws_vpc.pr_vpc.id

  tags = {
    Name = "igw-pr-${var.pr_id}"
  }
}

# Route Table Pública
resource "aws_route_table" "pr_public_rt" {
  vpc_id = aws_vpc.pr_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pr_igw.id
  }

  tags = {
    Name = "public-rt-pr-${var.pr_id}"
  }
}

# Associate subnets a Route Table
resource "aws_route_table_association" "pr_subnet_a_rt" {
  subnet_id      = aws_subnet.pr_subnet_a.id
  route_table_id = aws_route_table.pr_public_rt.id
}

resource "aws_route_table_association" "pr_subnet_b_rt" {
  subnet_id      = aws_subnet.pr_subnet_b.id
  route_table_id = aws_route_table.pr_public_rt.id
}
