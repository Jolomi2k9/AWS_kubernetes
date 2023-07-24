# --- loadbalancing/outputs.tf ---

output "tg_arn" {
  value = aws_lb_target_group.tg.arn
}

output "lb_endpoint" {
  value = aws_lb.alb.dns_name
}