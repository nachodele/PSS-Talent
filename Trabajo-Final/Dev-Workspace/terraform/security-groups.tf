# SG ALB (PÚBLICO controlado)
resource "aws_security_group" "pr_alb_sg" {
  name_prefix = "pr-${var.pr_id}-alb"
  vpc_id      = aws_vpc.pr_vpc.id

  ingress {
    description = "HTTP public ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Internet outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "sg-alb-pr-${var.pr_id}"
    PR_ID = var.pr_id
  }
}

# SG EC2 (SSH + ALB → HTTP)
resource "aws_security_group" "pr_ec2_sg" {
  name_prefix = "pr-${var.pr_id}-ec2"
  vpc_id      = aws_vpc.pr_vpc.id

  ingress {
    description = "SSH Ansible deploy"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH público (key protege)
  }

  ingress {
    description     = "ALB to EC2 HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.pr_alb_sg.id]
  }

  egress {
    description = "Internet outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "sg-ec2-pr-${var.pr_id}"
    PR_ID = var.pr_id
  }
}

# --------- APPLICATION LOAD BALANCER ---------
resource "aws_lb" "pr_alb" {
  name               = "alb-pr-${var.pr_id}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.pr_alb_sg.id]

  #  FIX: subnets (plural) - 2 AZs
  subnets = [
    aws_subnet.pr_subnet_a.id,
    aws_subnet.pr_subnet_b.id
  ]

  tags = {
    Name  = "alb-pr-${var.pr_id}"
    PR_ID = var.pr_id
  }
}

resource "aws_lb_target_group" "pr_tg" {
  name     = "tg-pr-${var.pr_id}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.pr_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name  = "tg-pr-${var.pr_id}"
    PR_ID = var.pr_id
  }
}

resource "aws_lb_listener" "pr_listener" {
  load_balancer_arn = aws_lb.pr_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pr_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "pr_tg_attachment" {
  target_group_arn = aws_lb_target_group.pr_tg.arn
  target_id        = aws_instance.pr_instance.id
  port             = 80
}
