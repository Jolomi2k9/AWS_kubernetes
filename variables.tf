# --- root/variables.tf ---

variable "access_ip" {}
variable "ssh_port" {}
variable "http_port" {}
variable "https_port" {}
variable "nginx_port" {}
variable "rds_port" {}
variable "dbname" {}
variable "dbuser" {}
variable "dbpass" {
  type      = string
  sensitive = true
}
variable "public_key_path" {}
variable "private_key_path" {}

