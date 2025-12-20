resource "aws_instance" "pr_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.pr_subnet_a.id
  vpc_security_group_ids = [aws_security_group.pr_ec2_sg.id]
  key_name               = data.aws_key_pair.ssh_key_nachodele.key_name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
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

# Target Group Attachment
resource "aws_lb_target_group_attachment" "pr_tg_attach" {
  target_group_arn = aws_lb_target_group.pr_tg.arn
  target_id        = aws_instance.pr_instance.id
  port             = 80
}
