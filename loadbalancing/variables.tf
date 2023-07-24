# --- loadbalancing/variables.tf ---

variable "loadbalancer_sg" {}
variable "public_subnets" {}
variable "tg_port" {}
variable "tg_protocol" {}
variable "vpc_id" {}
variable "alb_healthy_threshold" {}
variable "alb_unhealthy_threshold" {}
variable "alb_timeout" {}
variable "alb_interval" {}
variable "listener_port" {}
variable "listener_protocol" {}