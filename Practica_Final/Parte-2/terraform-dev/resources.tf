# VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "custom-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "custom-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnets" {
  for_each = { for sn in local.public_subnets : sn.name => sn }

  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.name
  }
}

# Private Subnets
resource "aws_subnet" "private_subnets" {
  for_each = { for sn in local.private_subnets : sn.name => sn }

  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Name = each.value.name
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_associations" {
  for_each = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IPs for NAT gateways (one per public subnet)
resource "aws_eip" "nat_eip" {
  for_each = aws_subnet.public_subnets
  domain   = "vpc"

  tags = {
    Name = "nat-eip-${each.key}"
  }
}

# NAT Gateways (one per public subnet)
resource "aws_nat_gateway" "nat_gw" {
  for_each      = aws_subnet.public_subnets
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = each.value.id

  tags = {
    Name = "nat-gateway-${each.key}"
  }
}

# Private Route Tables (one per private subnet)
resource "aws_route_table" "private_rt" {
  for_each = aws_subnet.private_subnets
  vpc_id   = aws_vpc.custom_vpc.id

  tags = {
    Name = "private-route-table-${each.key}"
  }
}

# Route from private route tables to corresponding NAT Gateway
resource "aws_route" "private_nat_route" {
  for_each = aws_route_table.private_rt

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.nat_gw[replace(each.key, "private-subnet", "public-subnet")].id
}

# Associate private subnets with their route tables
resource "aws_route_table_association" "private_associations" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt[each.key].id
}

# Key pair SSH
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Key pair SSH
resource "aws_key_pair" "generated_key" {
  key_name   = "ssh_key_nachodele"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Security Group for Web Servers
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP, HTTPS, and SSH"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Database Servers
resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Database security group"
  vpc_id      = aws_vpc.custom_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group Rule allowing Web Server SG to access DB SG on MySQL port
resource "aws_security_group_rule" "db_allow_web" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.web.id
  description              = "Allow MySQL access from web servers"
}

# EC2 instance for Webserver
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnets["public-subnet-1"].id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name = aws_key_pair.generated_key.key_name
  
  tags = {
    Name = "web-server"
    role = "web"
  }
}

# EC2 instance for Database server
resource "aws_instance" "db_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_subnets["private-subnet-1"].id
  vpc_security_group_ids = [aws_security_group.db.id]
  key_name = aws_key_pair.generated_key.key_name

  tags = {
    Name = "db-server"
    role = "db"
  }
}
