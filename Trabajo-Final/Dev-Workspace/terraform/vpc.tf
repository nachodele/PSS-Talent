resource "aws_vpc" "pr_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name  = "vpc-pr-${var.pr_id}"
    PR_ID = var.pr_id
  }
}

resource "aws_subnet" "pr_subnet" {
  vpc_id                  = aws_vpc.pr_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name  = "subnet-pr-${var.pr_id}"
    PR_ID = var.pr_id
  }
}

resource "aws_internet_gateway" "pr_igw" {
  vpc_id = aws_vpc.pr_vpc.id
  tags = {
    Name  = "igw-pr-${var.pr_id}"
    PR_ID = var.pr_id
  }
}

resource "aws_route_table" "pr_rt" {
  vpc_id = aws_vpc.pr_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pr_igw.id
  }
  tags = {
    Name  = "rt-pr-${var.pr_id}"
    PR_ID = var.pr_id
  }
}

resource "aws_route_table_association" "pr_rta" {
  subnet_id      = aws_subnet.pr_subnet.id
  route_table_id = aws_route_table.pr_rt.id
}
