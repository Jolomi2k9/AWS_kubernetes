# --- compute/main.tf ---

data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}


resource "random_id" "tr_instance_id" {
  byte_length = 2
  count       = var.instance_count
  #forces random id to also be replaced when instances are replaced
  keepers = {
    key_name = var.key_name
  }
}

resource "aws_key_pair" "tr_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "tr_node" {
  count         = var.instance_count
  instance_type = var.instance_type 
  ami           = data.aws_ami.server_ami.id

  tags = {
    Name = "tr_node-${random_id.tr_instance_id[count.index].dec}"
  }

  key_name               = aws_key_pair.tr_auth.id
  vpc_security_group_ids = [var.public_sg]
  subnet_id              = var.public_subnets[count.index]
  user_data              = templatefile(var.user_data_path,
    {
      nodename = "tr-${random_id.tr_instance_id[count.index].dec}" 
      db_endpoint = var.db_endpoint
      dbuser = var.dbuser
      dbpass = var.dbpass
      dbname = var.dbname
    }    
  )

  root_block_device {
    volume_size = var.vol_size
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.public_ip
      private_key = file(var.private_key_path)
    }
    script = "${path.root}/delay.sh"
  }
  provisioner "local-exec" {
    command = templatefile("${path.cwd}/scp_script.tpl",
      {
        nodeip   = self.public_ip
        k3s_path = "${path.cwd}/../"
        nodename = self.tags.Name
      }
    )
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.cwd}/../k3s-mtc_node-*"
  } 
}

resource "aws_lb_target_group_attachment" "tr_tg_attach" {
  count = var.instance_count
  target_group_arn = var.lb_tg_arn
  target_id        = aws_instance.tr_node[count.index].id
  port             = var.nginx_port
}





