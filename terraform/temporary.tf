# ALB Resources
data "aws_alb" "default" {
  count = var.exist ? 1 : 0
  name  = "default"
}
data "aws_alb_listener" "https" {
  count             = var.exist ? 1 : 0
  load_balancer_arn = var.exist ? data.aws_alb.default[0].arn : null
  port              = 443
}
resource "aws_alb_listener_rule" "this" {
  count        = var.exist ? 1 : 0
  listener_arn = var.exist ? data.aws_alb_listener.https[0].arn : null
  condition {
    host_header {
      values = [var.exist ? aws_route53_record.this[0].fqdn : null]
    }
  }
  action {
    type = "forward"
    forward {
      dynamic "target_group" {
        for_each = aws_alb_target_group.this
        content {
          arn = target_group.value["arn"]
        }
      }
    }
  }
}

# Route53
data "aws_route53_zone" "this" {
  name = "nimowagukari.net"
}
resource "aws_route53_record" "this" {
  count   = var.exist ? 1 : 0
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "codepipeline-tutorial.nimowagukari.net"
  type    = "A"
  alias {
    name                   = var.exist ? data.aws_alb.default[0].dns_name : null
    zone_id                = var.exist ? data.aws_alb.default[0].zone_id : null
    evaluate_target_health = true
  }
}

# ECS
data "aws_ecs_cluster" "default" {
  cluster_name = "default"
}
data "aws_ecs_task_definition" "this" {
  task_definition = "codepipeline-tutorial"
}
data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.develop.id]
  }
  filter {
    name   = "tag:subnet-type"
    values = ["public"]
  }
}
data "aws_security_group" "internal" {
  vpc_id = data.aws_vpc.develop.id
  filter {
    name   = "group-name"
    values = ["internal"]
  }
}
resource "aws_ecs_service" "this" {
  name            = "codepipeline-tutorial"
  cluster         = data.aws_ecs_cluster.default.cluster_name
  launch_type     = "FARGATE"
  task_definition = data.aws_ecs_task_definition.this.arn
  desired_count   = 1
  network_configuration {
    subnets = data.aws_subnets.this.ids
    security_groups = [
      data.aws_security_group.internal.id
    ]
    assign_public_ip = true
  }
  dynamic "load_balancer" {
    for_each = var.exist ? aws_alb_target_group.this : []
    content {
      target_group_arn = var.exist ? load_balancer.value["arn"] : null
      container_name   = "app"
      container_port   = 80
    }
  }
  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition
    ]
  }
}
