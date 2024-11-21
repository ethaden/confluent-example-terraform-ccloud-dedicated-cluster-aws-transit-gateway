
# resource "aws_route53_record" "postgres" {
#   zone_id = aws_route53_zone.private.zone_id
#   name    = var.hosted_zone_domain
#   type    = "A"
#   ttl     = "60"
#   records = [aws_db_instance.database.]
# }

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

# locals {
#   dns_server = cidrhost(data.aws_vpc.vpc.cidr_block, 2)
# }

# resource "confluent_dns_forwarder" "dns_forwarder" {
#   display_name = "dns_forwarder"
#   environment {
#     id = confluent_environment.myenv.id
#   }
#   domains = [aws_db_instance.database.address]
#   gateway {
#     id = confluent_network.net.gateway[0].id
#   }
#   forward_via_ip {
#     dns_server_ips = [local.dns_server]
#   }
# }

resource "aws_s3_bucket" "bucket" {
    bucket = var.s3_bucket_name

  tags = {
    Name        = var.s3_bucket_name
  }
  lifecycle {
    prevent_destroy = false
  }
}
