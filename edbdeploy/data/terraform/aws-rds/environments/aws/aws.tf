variable "aws_ami_id" {}
variable "pem_server" {}
variable "barman_server" {}
variable "pooler_server" {}
variable "hammerdb_server" {}
variable "replication_type" {}
variable "vpc_id" {}
variable "ssh_user" {}
variable "ssh_pub_key" {}
variable "ssh_priv_key" {}
variable "custom_security_group_id" {}
variable "cluster_name" {}
variable "created_by" {}
variable "ansible_inventory_yaml_filename" {}
variable "add_hosts_filename" {}
variable "barman" {}
variable "pooler_type" {}
variable "pooler_local" {}
variable "hammerdb" {}
variable "public_cidrblock" {}
variable "project_tag" {}
variable "pg_version" {}
variable "postgres_server" {}
variable "rds_security_group_id" {}

locals {
  lnx_ebs_device_names = [
    "/dev/sdf",
    "/dev/sdg",
    "/dev/sdh",
    "/dev/sdi",
    "/dev/sdj"
  ]
}

locals {
  lnx_nvme_device_names = [
    "/dev/nvme1n1",
    "/dev/nvme2n1",
    "/dev/nvme3n1",
    "/dev/nvme4n1",
    "/dev/nvme5n1",
  ]
}

locals {
  barman_mount_points = [
    "/var/lib/barman"
  ]
}

data "aws_subnet_ids" "selected" {
  vpc_id = var.vpc_id
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.cluster_name
  public_key = file(var.ssh_pub_key)
}

resource "aws_instance" "hammerdb_server" {
  count = var.hammerdb_server["count"]

  ami = var.aws_ami_id

  instance_type          = var.hammerdb_server["instance_type"]
  key_name               = aws_key_pair.key_pair.id
  subnet_id              = element(tolist(data.aws_subnet_ids.selected.ids), count.index)
  vpc_security_group_ids = [var.custom_security_group_id]

  root_block_device {
    delete_on_termination = "true"
    volume_size           = var.hammerdb_server["volume"]["size"]
    volume_type           = var.hammerdb_server["volume"]["type"]
    iops                  = var.hammerdb_server["volume"]["type"] == "io2" ?  var.hammerdb_server["volume"]["iops"] : var.hammerdb_server["volume"]["type"] == "io1" ? var.hammerdb_server["volume"]["iops"] : null
  }

  tags = {
    Name       = format("%s-%s%s", var.cluster_name, "hammerdbserver", count.index + 1)
    Created_By = var.created_by
  }

  connection {
    private_key = file(var.ssh_pub_key)
  }
}

resource "aws_instance" "pem_server" {
  count = var.pem_server["count"]

  ami = var.aws_ami_id

  instance_type          = var.pem_server["instance_type"]
  key_name               = aws_key_pair.key_pair.id
  subnet_id              = element(tolist(data.aws_subnet_ids.selected.ids), count.index)
  vpc_security_group_ids = [var.custom_security_group_id]

  root_block_device {
    delete_on_termination = "true"
    volume_size           = var.pem_server["volume"]["size"]
    volume_type           = var.pem_server["volume"]["type"]
    iops                  = var.pem_server["volume"]["type"] == "io2" ? var.pem_server["volume"]["iops"] : var.pem_server["volume"]["type"] == "io1" ? var.pem_server["volume"]["iops"] : null
  }

  tags = {
    Name       = format("%s-%s%s", var.cluster_name, "pemserver", count.index + 1)
    Created_By = var.created_by
  }

  connection {
    private_key = file(var.ssh_pub_key)
  }
}

resource "aws_instance" "barman_server" {
  count = var.barman_server["count"]

  ami = var.aws_ami_id

  instance_type          = var.barman_server["instance_type"]
  key_name               = aws_key_pair.key_pair.id
  subnet_id              = element(tolist(data.aws_subnet_ids.selected.ids), count.index)
  vpc_security_group_ids = [var.custom_security_group_id]

  root_block_device {
    delete_on_termination = "true"
    volume_size           = var.barman_server["volume"]["size"]
    volume_type           = var.barman_server["volume"]["type"]
    iops                  = var.barman_server["volume"]["type"] == "io2" ? var.barman_server["volume"]["iops"] : var.barman_server["volume"]["type"] == "io1" ? var.barman_server["volume"]["iops"] : null
  }

  tags = {
    Name       = format("%s-%s%s", var.cluster_name, "barman", count.index + 1)
    Created_By = var.created_by
  }

  connection {
    private_key = file(var.ssh_pub_key)
  }
}

resource "aws_instance" "pooler_server" {
  count = var.pooler_server["count"]

  ami = var.aws_ami_id

  instance_type          = var.pooler_server["instance_type"]
  key_name               = aws_key_pair.key_pair.id
  subnet_id              = element(tolist(data.aws_subnet_ids.selected.ids), count.index)
  vpc_security_group_ids = [var.custom_security_group_id]

  root_block_device {
    delete_on_termination = "true"
    volume_size           = var.pooler_server["volume"]["size"]
    volume_type           = var.pooler_server["volume"]["type"]
    iops                  = var.pooler_server["volume"]["type"] == "io2" ? var.pooler_server["volume"]["iops"] : var.pooler_server["volume"]["type"] == "io1" ? var.pooler_server["volume"]["iops"] : null
  }

  tags = {
    Name       = format("%s-%s%s", var.cluster_name, "pooler", count.index + 1)
    Created_By = var.created_by
  }

  connection {
    private_key = file(var.ssh_pub_key)
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = format("%s-%s", var.cluster_name, "rds-subset-group")
  subnet_ids = tolist(data.aws_subnet_ids.selected.ids)

  tags = {
    Name       = format("%s-%s", var.cluster_name, "rds-subset-group")
    Created_By = var.created_by
  }
}

resource "aws_db_instance" "rds_server" {
  allocated_storage        = var.postgres_server["volume"]["size"]
  backup_retention_period  = 0
  db_subnet_group_name     = aws_db_subnet_group.rds.id
  engine                   = "postgres"
  engine_version           = var.pg_version
  identifier               = var.cluster_name
  instance_class           = var.postgres_server["instance_type"]
  multi_az                 = false
  name                     = var.cluster_name
  parameter_group_name     = format("default.postgres%s", var.pg_version)
  password                 = "postgres"
  port                     = 5432
  publicly_accessible      = true
  storage_encrypted        = false
  storage_type             = var.postgres_server["volume"]["type"]
  iops                     = var.postgres_server["volume"]["iops"]
  username                 = "postgres"
  vpc_security_group_ids   = [var.rds_security_group_id]
  skip_final_snapshot      = true

  tags = {
    Name       = format("%s-%s", var.cluster_name, "rds")
    Created_By = var.created_by
  }
}
