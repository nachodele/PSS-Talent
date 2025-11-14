# --------- Generación de sufijo aleatorio para naming ---------
#resource "random_id" "suffix" {
#  byte_length = 4
#}

# --------- Bucket S3 para almacenamiento estático ---------
#resource "aws_s3_bucket" "project_bucket" {
#  bucket = "${local.project}-nachodele-${random_id.suffix.hex}"

#  tags = merge(local.common_tags, var.additional_tags)
#}

# Política pública para permitir lectura de objetos en el bucket
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = data.aws_s3_bucket.existing_bucket.bucket
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${data.aws_s3_bucket.existing_bucket.arn}/*"
      }
    ]
  })
}

# Configuración de acceso público al bucket S3
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = data.aws_s3_bucket.existing_bucket.bucket
  
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Configuración de sitio web estático para el bucket S3
resource "aws_s3_bucket_website_configuration" "static_website" {
  bucket = data.aws_s3_bucket.existing_bucket.bucket
  
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Objetos estáticos dentro del bucket (archivos web)
resource "aws_s3_object" "website_files" {
  for_each    = local.website_files
  bucket = data.aws_s3_bucket.existing_bucket.bucket
  key         = each.key
  source      = each.value
  etag        = filemd5(each.value)
  content_type = "text/html"
}

# --------- VPC y Redes ---------

# VPC personalizada
resource "aws_vpc" "custom_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "custom-vpc"
  }
}

# Internet Gateway asociado a la VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "custom-igw"
  }
}

# Subredes públicas
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

# Subredes privadas
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

# Tabla de rutas pública
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

# Asociación de tabla rutas pública con subredes públicas
resource "aws_route_table_association" "public_associations" {
  for_each = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

# IPs elásticas para NAT gateways
resource "aws_eip" "nat_eip" {
  for_each = aws_subnet.public_subnets
  domain   = "vpc"

  tags = {
    Name = "nat-eip-${each.key}"
  }
}

# NAT gateways por cada subred pública
resource "aws_nat_gateway" "nat_gw" {
  for_each      = aws_subnet.public_subnets
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = each.value.id

  tags = {
    Name = "nat-gateway-${each.key}"
  }
}

# Tablas de ruta privadas
resource "aws_route_table" "private_rt" {
  for_each = aws_subnet.private_subnets
  vpc_id   = aws_vpc.custom_vpc.id

  tags = {
    Name = "private-route-table-${each.key}"
  }
}

# Ruta en tabla privada hacia NAT gateway correspondiente
resource "aws_route" "private_nat_route" {
  for_each = aws_route_table.private_rt

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.nat_gw[replace(each.key, "private-subnet", "public-subnet")].id
}

# Asociación de tabla ruta privada con subredes privadas
resource "aws_route_table_association" "private_associations" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt[each.key].id
}

# --------- Claves SSH ---------

# Clave RSA privada generada localmente para acceso SSH
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Registro de clave pública en AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "ssh_key_nachodele"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Guardar clave privada localmente con permisos seguros
resource "local_file" "private_key_pem" {
  content          = tls_private_key.ssh_key.private_key_pem
  filename         = "${path.module}/ssh_key_nachodele.pem"
  file_permission  = "0400"
}

# --------- Grupos de Seguridad ---------

# Security Group para servidores web permitiendo HTTP, HTTPS y SSH
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

# Security Group para servidores de base de datos
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

# Regla para permitir que servidores web accedan a base de datos por puerto MySQL 3306
resource "aws_security_group_rule" "db_allow_web" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.web.id
  description              = "Allow MySQL access from web servers"
}

# --------- Instancias EC2 ---------

# Instancia EC2 para servidor web
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnets["public-subnet-1"].id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.generated_key.key_name

  tags = {
    Name = "web-server"
    role = "web"
  }
}

# Instancia EC2 para servidor base de datos
resource "aws_instance" "db_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_subnets["private-subnet-1"].id
  vpc_security_group_ids = [aws_security_group.db.id]
  key_name               = aws_key_pair.generated_key.key_name

  tags = {
    Name = "db-server"
    role = "db"
  }
}
