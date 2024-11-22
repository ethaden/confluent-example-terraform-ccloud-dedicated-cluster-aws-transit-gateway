
resource "aws_route53_zone" "mariadb" {
    name = var.hosted_zone_domain
}

resource "aws_route53_record" "mariadb" {
  zone_id = aws_route53_zone.mariadb.zone_id
  name    = "mariadb"
  type    = "A"
  ttl     = "60"
  records = tolist(aws_network_interface.mariadb_iface.private_ips)
}

# resource "aws_db_subnet_group" "database" {
#   name       = "${var.resource_prefix}database"
#   subnet_ids = data.aws_subnets.vpc_subnets.ids

#   tags = {
#     Name = "${var.resource_prefix}database"
#   }
# }

# resource "aws_db_instance" "database" {
#   identifier             = var.db_identifier
#   instance_class         = "db.t3.micro"
#   allocated_storage      = 5
#   engine                 = "postgres"
#   engine_version         = "17.1"
#   username               = "edu"
#   password               = var.db_password
#   db_subnet_group_name   = aws_db_subnet_group.database.name
#   #vpc_security_group_ids = [aws_security_group.rds.id]
#   parameter_group_name   = aws_db_parameter_group.database.name
#   publicly_accessible    = false
#   skip_final_snapshot    = true
#   multi_az               = true
#   network_type           = "DUAL"
# }

# resource "aws_db_parameter_group" "database" {
#   name   = "education"
#   family = "postgres17"

#   parameter {
#     name  = "log_connections"
#     value = "1"
#   }
# }

data "aws_ami" "bitnami_mariadb_ami" {
  # Bitnami
  owners = ["679593333241"]
  most_recent = true
  name_regex       = "^bitnami-mysql-.*-.*-linux-debian-12-x86_64-.*"

#   filter {
#     name   = "name"
#     #values = ["ubuntu/images/ubuntu-*-*-amd64-server-*"]
#     values = ["aws-marketplace/bitnami-mysql-*-*-linux-debian-12-x86_64-*"]
#   }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "sg_mariadb" {
  name        = "${local.resource_prefix}-mariadb"
  description = "Allow only SSH and MariaDB port and only from internal addresses"
  vpc_id      = data.aws_vpc.vpc.id

  # Generate dualstack ingress for for the following tcp ports: 22 (ssh), 80 (http), 443 (https)
  # Alternatively, only for port 22
  dynamic "ingress" {
    #for_each = { 1 : 22, 2 : 80, 3 : 443 }
    for_each = { 1 : 22, 2: 3306 }
    content {
      protocol         = "tcp"
      from_port        = ingress.value
      to_port          = ingress.value
      cidr_blocks      = [data.aws_vpc.vpc.cidr_block]
      ipv6_cidr_blocks = [data.aws_vpc.vpc.ipv6_cidr_block]

    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    prevent_destroy = false
  }
}

# data "aws_key_pair" "user_ssh" {
#   key_name           = var.ssh_key_name
#   include_public_key = true
# }


# data "aws_iam_user_ssh_key" "user_ssh" {
#   encoding          = "SSH"
#   #ssh_public_key_id = "APKARUZ32GUTKIGARLXE"
#   username          = var.ssh_key_name
# }

resource "aws_network_interface" "mariadb_iface" {
  subnet_id   = data.aws_subnet.vpc_subnet[0].id
  private_ips = [cidrhost(data.aws_subnet.vpc_subnet.0.cidr_block, 100)]
  security_groups = [
    aws_security_group.sg_mariadb.id
  ]

  tags = {
    Name = "${var.resource_prefix}_mariadb_iface"
  }
}

resource "aws_instance" "ec2_mariadb" {
  ami           = data.aws_ami.bitnami_mariadb_ami.id
  instance_type = var.database_instance_type
  # Use availability zone of the chosen subnets
  #availability_zone = data.terraform_remote_state.common_vpc.outputs.subnet_dualstack_1b.availability_zone
  key_name          = var.ssh_key_name
  hibernation       = true
  disable_api_termination = true

  network_interface {
    network_interface_id = aws_network_interface.mariadb_iface.id
    device_index         = 0
  }

  root_block_device {
    delete_on_termination = true
    volume_size           = 100
    volume_type           = "gp3"
    tags                  = local.confluent_tags
    encrypted             = true
  }

  #user_data = data.cloudinit_config.ec2_instance_init.rendered
  metadata_options {
     # recommended by AWS
    http_tokens = "required"
  }
  tags = {
    Name = "${local.resource_prefix}-mariadb"
  }

  # depends_on = [ aws_security_group.project-iac-sg ]
}

# provider "mysql" {
#   endpoint = "${aws_db_instance.default.endpoint}"
#   username = "root"
#   password = var.
#   depends_on = [ aws_instance.ec2_mariadb ]
# }

# # Create a second database, in addition to the "initial_db" created
# # by the aws_db_instance resource above.
# resource "mysql_database" "app" {
#   name = "another_db"
# }

locals {
  dns_server = cidrhost(data.aws_vpc.vpc.cidr_block, 2)
}

resource "confluent_dns_forwarder" "dns_forwarder" {
  display_name = "dns_forwarder"
  environment {
    id = confluent_environment.myenv.id
  }
  domains = [var.hosted_zone_domain]
  gateway {
    id = confluent_network.net.gateway[0].id
  }
  forward_via_ip {
    dns_server_ips = [local.dns_server]
  }
}

