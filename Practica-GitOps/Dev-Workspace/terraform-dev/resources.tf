# --------- Generación de sufijo aleatorio para naming ---------
#resource "random_id" "suffix" {
#  byte_length = 4
#}

# --------- Bucket S3 para almacenamiento estático ---------
#resource "aws_s3_bucket" "project_bucket" {
#  bucket = "${local.project}-nachodele-${random_id.suffix.hex}"

#  tags = merge(local.common_tags)
#}

# --------- VPC y Redes ---------

resource "aws_vpc" "custom_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name  = "custom-vpc"
    Owner = local.common_tags.Owner
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name  = "custom-igw"
    Owner = local.common_tags.Owner
  }
}

resource "aws_subnet" "public_subnets" {
  for_each = { for sn in local.public_subnets : sn.name => sn }

  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name  = each.value.name
    Owner = local.common_tags.Owner
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = { for sn in local.private_subnets : sn.name => sn }

  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Name  = each.value.name
    Owner = local.common_tags.Owner
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name  = "public-route-table"
    Owner = local.common_tags.Owner
  }
}

resource "aws_route_table_association" "public_associations" {
  for_each = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "nat_eip" {
  for_each = aws_subnet.public_subnets
  domain   = "vpc"

  tags = {
    Name  = "nat-eip-${each.key}"
    Owner = local.common_tags.Owner
  }
}

resource "aws_nat_gateway" "nat_gw" {
  for_each      = aws_subnet.public_subnets
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = each.value.id

  tags = {
    Name  = "nat-gateway-${each.key}"
    Owner = local.common_tags.Owner
  }
}

resource "aws_route_table" "private_rt" {
  for_each = aws_subnet.private_subnets
  vpc_id   = aws_vpc.custom_vpc.id

  tags = {
    Name  = "private-route-table-${each.key}"
    Owner = local.common_tags.Owner
  }
}

resource "aws_route" "private_nat_route" {
  for_each = aws_route_table.private_rt

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.nat_gw[replace(each.key, "private-subnet", "public-subnet")].id
}

resource "aws_route_table_association" "private_associations" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt[each.key].id
}

# --------- Claves SSH ---------
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ssh_key_nachodele"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = pathexpand("~/.ssh/nachodele.pem")
  file_permission = "0400"
}

# --------- Grupos de Seguridad ---------

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP and HTTPS from anywhere"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Owner = local.common_tags.Owner
  }
}

resource "aws_security_group" "asg_sg" {
  name        = "asg-sg"
  description = "Allow HTTP, HTTPS from ALB and SSH from anywhere"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
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

  tags = {
    Owner = local.common_tags.Owner
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow PostgreSQL from EC2 instances"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.asg_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Owner = local.common_tags.Owner
  }
}

# --------- Application Load Balancer ---------

resource "aws_lb" "alb" {
  name               = "nachodele-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for k, v in aws_subnet.public_subnets : v.id]

  tags = {
    Name  = "nachodele-alb"
    Owner = local.common_tags.Owner
  }
}

resource "aws_lb_target_group" "asg_tg" {
  name     = "asg-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "asg_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg_tg.arn
  }
}

# --------- AutoScaling Group ---------

resource "aws_launch_template" "asg_lt" {
  name_prefix             = "nachodele-asg-"
  image_id                = data.aws_ami.ubuntu.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.generated_key.key_name
  vpc_security_group_ids  = [aws_security_group.asg_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "ASG-nachodele"
      Owner   = local.common_tags.Owner
      Project = local.common_tags.Project
      Role    = "webserver"          # Agregado para la etiqueta Role
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name                  = "nachodele"
  min_size              = var.asg_min_size
  max_size              = var.asg_max_size
  desired_capacity      = var.asg_min_size
  vpc_zone_identifier   = [for k, v in aws_subnet.public_subnets : v.id]
  target_group_arns     = [aws_lb_target_group.asg_tg.arn]

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 30
  force_delete              = true

  dynamic "tag" {
    for_each = var.asg_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = "web-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = local.common_tags.Project
    propagate_at_launch = true
  }

  tag {
    key                 = "Owner"
    value               = local.common_tags.Owner
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"             # Agregado para propagar la etiqueta Role a las instancias
    value               = "webserver"
    propagate_at_launch = true
  }
}


# --------- RDS PostgreSQL ---------

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [for k, v in aws_subnet.private_subnets : v.id]

  tags = {
    Name  = "rds-subnet-group"
    Owner = local.common_tags.Owner
  }
}

resource "aws_db_instance" "rds" {
  identifier             = "rds-postgress"
  engine                 = "postgres"
  engine_version         = "14"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "postgres"
  password               = var.rds_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name    = "nachodele-rds"
    Owner   = local.common_tags.Owner
    Project = local.common_tags.Project
  }
} 
