# --- root/main.tf ---

module "networking" {
  source   = "./networking"
  vpc_cidr = local.vpc_cidr
  #number of subnet to generate
  private_sn_count = 3
  public_sn_count  = 2
  max_subnets      = 20
  access_ip        = var.access_ip
  security_groups  = local.security_groups
  #for loop to generate subnet numbers using cidrsubnet function
  private_cidrs = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  public_cidrs  = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  db_subnet_group  = false
}

module "loadbalancing" {
  source                  = "./loadbalancing"
  loadbalancer_sg         = module.networking.alb_sg
  public_subnets          = module.networking.public_subnets
  tg_port                 = var.http_port
  tg_protocol             = "HTTP"
  vpc_id                  = module.networking.vpc_id
  alb_healthy_threshold   = 2
  alb_unhealthy_threshold = 2
  alb_timeout             = 3
  alb_interval            = 30
  listener_port           = var.http_port
  listener_protocol       = "HTTP"
}

module "compute" {
  source         = "./compute"
  public_sg      = module.networking.public_sg
  public_subnets = module.networking.public_subnets  
  instance_count = 2
  instance_type  = "t2.small"  
  vol_size       = "10"
  public_key_path = var.public_key_path
  private_key_path= var.private_key_path
  key_name        = "trkey" 
  user_data_path  = "userdata.tpl"
  dbname                 = var.dbname
  dbuser                 = var.dbuser
  dbpass                 = var.dbpass
  db_endpoint            = module.database.db_endpoint
  lb_tg_arn              = module.loadbalancing.tg_arn
  nginx_port             = var.nginx_port
}

module "database" {
  source                 = "./database"
  db_engine_version      = "5.7.22"
  db_instance_class      = "db.t2.micro"
  dbname                 = var.dbname
  dbuser                 = var.dbuser
  dbpass             = var.dbpass
  db_identifier          = "tr-db"
  skip_db_snapshot       = true
  # db_subnet_group_name   = module.networking.db_subnet_group_name[0]
  db_subnet_group_name   = length(module.networking.db_subnet_group_name) > 0 ? module.networking.db_subnet_group_name[0] : null
  vpc_security_group_ids = [module.networking.db_security_group]
}