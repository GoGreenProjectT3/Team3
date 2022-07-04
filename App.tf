resource "aws_lb" "app" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_app.id]
  subnets            = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
  tags = {
    "Name" = "APP"
  }
}

resource "aws_launch_configuration" "ec2_launcher2" {
  name_prefix                 = "app-alb-launcher"
  image_id                    = data.aws_ami.amznlx2.id
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  security_groups             = [aws_security_group.appserver-security-group2.id]
  user_data                   = file("user_data.sh")
  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_autoscaling_group" "app-scaling-rule" {
  name                 = "apptier-scaling"
  vpc_zone_identifier  = [aws_subnet.private_subnet3.id, aws_subnet.private_subnet4.id]
  launch_configuration = aws_launch_configuration.ec2_launcher2.name
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "app-tier"
    propagate_at_launch = "true"
  }
  #  tag {
  #     key                 = "lorem"
  #     value               = "ipsum"
  #     propagate_at_launch = false
  #   }

}
resource "aws_lb_target_group" "app_target_group" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {

    interval            = 70
    path                = "/index.php"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60
    protocol            = "HTTP"
    matcher             = "200,202"

  }
}
resource "aws_lb_listener" "lb_listener2" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

resource "aws_autoscaling_attachment" "alb_asg_attach2" {
  autoscaling_group_name = aws_autoscaling_group.app-scaling-rule.id
  alb_target_group_arn   = aws_lb_target_group.app_target_group.arn
}

resource "aws_autoscaling_policy" "app_policy_up" {
  name                   = "app_policy_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app-scaling-rule.name
}
resource "aws_cloudwatch_metric_alarm" "app_cpu_alarm_up" {
  alarm_name          = "app_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app-scaling-rule.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.app_policy_up.arn]
}
resource "aws_autoscaling_policy" "app_policy_down" {
  name                   = "app_policy_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app-scaling-rule.name
}
resource "aws_cloudwatch_metric_alarm" "app_cpu_alarm_down" {
  alarm_name          = "app_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app-scaling-rule.name
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.app_policy_down.arn]
}