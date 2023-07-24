# --- database/variables.tf ---

variable "db_instance_class" {}
variable "dbname" {}
variable "dbuser" {}
variable "dbpass" {}
variable "vpc_security_group_ids" {}
variable "db_subnet_group_name" {}
variable "db_engine_version" {}
variable "db_identifier" {}
variable "skip_db_snapshot" {}