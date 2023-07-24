
locals {
  vpc_cidr = "10.0.0.0/16"
}

locals {
  security_groups = {
    public = {
      name        = "public_sg"
      description = "public access"
      ingress = {
        ssh = {
          from        = var.ssh_port
          to          = var.ssh_port
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }
        https = {
          from        = var.https_port
          to          = var.https_port
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }
        http = {
          from        = var.http_port
          to          = var.http_port
          protocol    = "tcp"                  
          cidr_blocks = [var.access_ip]
        }
        nginx = {
          from        = var.nginx_port
          to          = var.nginx_port
          protocol    = "tcp"                  
          cidr_blocks = [var.access_ip]
        }
      }
    }
    rds = {
      name        = "rds_sg"
      description = "Allow ports 3306"
      ingress = {
        jenkins = {
          from        = var.rds_port
          to          = var.rds_port
          protocol    = "tcp"
          cidr_blocks = [local.vpc_cidr]
        }
      }
    }
    loadbalancer = {
      name        = "alb_sg"
      description = "Allow ports 80"
      ingress = {
        http = {
          from        = var.http_port
          to          = var.http_port
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }        
      }
    }    
  }
}