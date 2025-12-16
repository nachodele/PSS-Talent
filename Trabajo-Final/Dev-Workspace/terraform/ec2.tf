data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


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
  filename        = "${path.module}/ssh_key_nachodele.pem"
  file_permission = "0400"
}


resource "aws_instance" "pr_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.pr_subnet.id
  vpc_security_group_ids = [aws_security_group.pr_sg.id]

  key_name = aws_key_pair.generated_key.key_name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name        = "ec2-pr-${var.pr_id}"
    Environment = "pr-${var.pr_id}"
    AutoDelete  = "true"
    PR_ID       = var.pr_id
  }

  lifecycle {
    prevent_destroy = false
  }
}
