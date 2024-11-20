resource "confluent_environment" "myenv" {
  display_name = "${var.resource_prefix}aws_transit_gateway"

  lifecycle {
    prevent_destroy = true
  }
}

resource "confluent_network" "net" {
    display_name = "${var.resource_prefix}aws-transit-gateway"
    cloud = "AWS"
    region = var.aws_region
    connection_types = ["TRANSITGATEWAY"]
    #zones           = []
    cidr             = "10.10.0.0/16"
    environment {
      id = confluent_environment.myenv.id
    }
}

resource "confluent_kafka_cluster" "dedicated" {
  display_name = "${var.resource_prefix}cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = var.aws_region
  dedicated {
    cku        = 1
  }
  environment {
    id = confluent_environment.myenv.id
  }
  network {
    id        = confluent_network.net.id
  }
}

# resource "confluent_dns_forwarder" "main" {
#   display_name = "dns_forwarder"
#   environment {
#     id = confluent_environment.development.id
#   }
#   domains = ["example.com", "domainname.com"]
#   gateway {
#     id = confluent_network.main.gateway[0].id
#   }
#   forward_via_ip {
#     dns_server_ips = ["10.200.0.0", "10.200.0.1"]
#   }
# }
