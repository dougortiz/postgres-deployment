resource "local_file" "AnsibleYamlInventory" {
  filename = "${abspath(path.root)}/${var.ansible_inventory_yaml_filename}"
  content  = <<EOT
---
all:
  children:
%{if var.pem_server["count"] > 0 ~}
    pemserver:
      hosts:
        pemserver1:
          ansible_host: ${aws_instance.pem_server[0].public_ip}
          private_ip: ${aws_instance.pem_server[0].private_ip}
%{endif ~}
%{if var.barman_server["count"] > 0 ~}
    barmanserver:
      hosts:
        barmanserver1:
          ansible_host: ${aws_instance.barman_server[0].public_ip}
          private_ip: ${aws_instance.barman_server[0].private_ip}
%{endif ~}
%{if var.hammerdb_server["count"] > 0 ~}
    hammerdbserver:
      hosts:
        hammerdbserver1:
          ansible_host: ${aws_instance.hammerdb_server[0].public_ip}
          private_ip: ${aws_instance.hammerdb_server[0].private_ip}
%{endif ~}
%{for pooler_count in range(var.pooler_server["count"]) ~}
%{if pooler_count == 0 ~}
%{if var.pooler_type == "pgpool2" ~}
    pgpool2:
%{endif ~}
%{if var.pooler_type == "pgbouncer" ~}
    pgbouncer:
%{endif ~}
      hosts:
%{endif ~}
        pooler${pooler_count + 1}:
          ansible_host: ${aws_instance.pooler_server[pooler_count].public_ip}
          private_ip: ${aws_instance.pooler_server[pooler_count].private_ip}
%{endfor ~}
    primary:
      hosts:
        primary1:
          ansible_host: ${aws_db_instance.rds_server.address}
          private_ip: ${aws_db_instance.rds_server.address}
EOT
}

resource "local_file" "host_script" {
  filename = "${abspath(path.root)}/${var.add_hosts_filename}"
  content  = <<-EOT
echo "Setting SSH Keys"
ssh-add ${var.ssh_priv_key}
echo "Adding IPs"
%{if var.pem_server["count"] > 0 ~}
ssh-keyscan -H ${aws_instance.pem_server[0].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.pem_server[0].public_dns}
%{endif ~}
%{if var.barman_server["count"] > 0 ~}
ssh-keyscan -H ${aws_instance.barman_server[0].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.barman_server[0].public_dns}
%{endif ~}
%{for count in range(var.pooler_server["count"]) ~}
ssh-keyscan -H ${aws_instance.pooler_server[count].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.pooler_server[count].public_dns}
%{endfor ~}
    EOT
}
