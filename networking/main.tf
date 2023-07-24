# --- networking/main.tf ---

#local value for azs
locals {
  azs = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {}

#random resource for generating vpc numbers
resource "random_integer" "random" {
    min = 1
    max = 100
}

#generates a randomized list of azs based on the number of azs available
resource "random_shuffle" "public_az" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

# Create a VPC
resource "aws_vpc" "production_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    #interpolation syntax for concacting random ids to string 
    Name = "production_vpc-${random_integer.random.id}"
  }
    #lifecycle to create a new vpc before destroying current vpc
  lifecycle {
    create_before_destroy = true
  }
}

# public subnets
resource "aws_subnet" "public_subnet" {
  count                   = var.public_sn_count
  vpc_id                  = aws_vpc.production_vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.public_az.result[count.index]

  tags = {
    Name = "public_subnet_${count.index + 1}"
  }
}
#public route association
resource "aws_route_table_association" "public_assoc" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.public_subnet.*.id[count.index]
  route_table_id = aws_route_table.public_rt.id
}

#private subnets
resource "aws_subnet" "private_subnet" {
  count                   = var.private_sn_count
  vpc_id                  = aws_vpc.production_vpc.id
  cidr_block              = var.private_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.public_az.result[count.index]

  tags = {
    Name = "private_subnet_${count.index + 1}"
  }
}
#private route association
resource "aws_route_table_association" "private_assoc" {
  count          = var.private_sn_count
  subnet_id      = aws_subnet.private_subnet.*.id[count.index]   
  route_table_id = aws_route_table.private_rt.*.id[count.index]
}

resource "aws_db_subnet_group" "rds_subnetgroup" {
  count      = var.db_subnet_group ? 1 : 0
  name       = "rds_subnetgroup"
  subnet_ids = aws_subnet.private_subnet.*.id
  tags = {
    Name = "rds_sng"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.production_vpc.id

  tags = {
    Name = "igw"
  }
}

# Create an elastic IP for our NAT gateway
# resource "aws_eip" "nat_eip"{
#   count = var.public_sn_count
#   #specify condition for creation
#   depends_on = [aws_internet_gateway.igw]

#   tags = {
#     Name = "nat_eip-${count.index + 1}"
#   }
# }

# # Create the NAT Gateway
# resource "aws_nat_gateway" "nat_gw"{
#   count = var.public_sn_count
#   #associate an elastic ip
#   allocation_id = aws_eip.nat_eip.*.id[count.index]
#   ##pull index from created public subnets
#   subnet_id = aws_subnet.public_subnet.*.id[count.index]

#   tags = {
#     Name = "Nat-Gateway-${count.index + 1}"
#   }
# }

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.production_vpc.id
  #route to igw
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}


resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.production_vpc.id
  count  = var.private_sn_count

  route{
    cidr_block = "0.0.0.0/0"
    #pull index from created natgateways
    # nat_gateway_id = aws_nat_gateway.nat_gw.*.id[count.index]

    gateway_id = aws_internet_gateway.igw.id
    
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_security_group" "sg" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.production_vpc.id



  #public Security Group
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  #
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
