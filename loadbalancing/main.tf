# --- loadbalancing/main.tf ---

resource "aws_lb" "alb" {
  name               = "loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.loadbalancer_sg]
  subnets            = var.public_subnets
  idle_timeout = 400

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

data "aws_lb" "ld_arn" {
  arn  = aws_lb.alb.arn
}

resource "aws_lb_target_group" "tg" {
  name     = "lb-tg-${substr(uuid(), 0, 3)}"
  port     = var.tg_port
  protocol = var.tg_protocol
  vpc_id   = var.vpc_id
  #ignore changes to name of target group
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
  health_check {
    healthy_threshold   = var.alb_healthy_threshold
    unhealthy_threshold = var.alb_unhealthy_threshold
    timeout             = var.alb_timeout
    interval            = var.alb_interval
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Request and validate an SSL certificate from AWS Certificate Manager 
resource "aws_acm_certificate" "my_certificate" {
  domain_name       = data.aws_lb.ld_arn.dns_name
  validation_method = "DNS"

  tags = {
    Name = " lb SSL certificate"
  }
}

# Associate the SSL certificate with the ALB listener
resource "aws_lb_listener_certificate" "my_certificate" {
  listener_arn = aws_lb_listener.alb_listener.arn
  certificate_arn = aws_acm_certificate.my_certificate.arn
}

#S3 bucket for logs
resource "aws_s3_bucket" "waf_logs_bucket" {
  bucket = "my-waf-log-bucket"

  tags = {
    Name        = "WAF logs"    
  }
}

#create WAF resource and rules
resource "aws_wafv2_web_acl" "tr_waf" {
  name        = "managed-rule-tr_waf"
  description = "managed rules for waf."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSRateBasedRuleDomesticDOS"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"

        scope_down_statement {
          geo_match_statement {
            country_codes = ["JP"]
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSRateBasedRuleDomesticDOS"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSRateBasedRuleGlobalDOS"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 500
        aggregate_key_type = "IP"

        scope_down_statement {
          not_statement {
            statement {
              geo_match_statement {
                country_codes = ["JP"]
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSRateBasedRuleGlobalDOS"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "managed-rule-tr_waf_ACL"
    sampled_requests_enabled   = true
  }

}
#WAF log destination
resource "aws_wafv2_web_acl_logging_configuration" "tr_waf_log" {
  log_destination_configs = [aws_s3_bucket.waf_logs_bucket.arn]
  resource_arn            = aws_wafv2_web_acl.tr_waf.arn
}

#Associate AWS resource
resource "aws_wafv2_web_acl_association" "waf_alb" {
  resource_arn = aws_lb.alb.arn
  web_acl_arn  = aws_wafv2_web_acl.tr_waf.arn
}