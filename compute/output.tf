# --- compute/output.tf ---

output "key_pair" {
  value = aws_key_pair.tr_auth.id
}

output "instance"{
  value = aws_instance.tr_node[*]
  sensitive = true
}

output "instance_port"{
  value = aws_lb_target_group_attachment.tr_tg_attach[0].port
}