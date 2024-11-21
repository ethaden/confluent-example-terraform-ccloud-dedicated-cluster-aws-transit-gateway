resource "confluent_environment" "myenv" {
  display_name = "${var.resource_prefix}aws_transit_gateway"

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

resource "aws_ram_principal_association" "confluent" {
  principal          = confluent_network.net.aws[0].account
  resource_share_arn = aws_ram_resource_share.tgw_share.arn
}

resource "confluent_transit_gateway_attachment" "confluent_tgw_attach" {
  display_name = "AWS Transit Gateway Attachment"
  aws {
    ram_resource_share_arn = aws_ram_resource_share.tgw_share.arn
    transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
    routes                 = ["172.29.0.0/16"]
  }
  environment {
    id = confluent_environment.myenv.id
  }
  network {
    id = confluent_network.net.id
  }
}

# Find the routing table
data "aws_route_tables" "rts" {
  vpc_id = var.vpc_id
}

resource "aws_route" "routes" {
  for_each               = toset(data.aws_route_tables.rts.ids)
  route_table_id         = each.key
  destination_cidr_block = confluent_network.net.cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}


# Topic with configured name
resource "confluent_kafka_topic" "example_dedicated_topic_test" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  topic_name         = var.ccloud_cluster_topic
  rest_endpoint      = confluent_kafka_cluster.dedicated.rest_endpoint
  partitions_count = 1
  credentials {
    key    = confluent_api_key.example_dedicated_api_key_sa_cluster_admin.id
    secret = confluent_api_key.example_dedicated_api_key_sa_cluster_admin.secret
  }

  # Required to make sure the role binding is created before trying to create a topic using these credentials
  depends_on = [ confluent_role_binding.example_dedicated_role_binding_cluster_admin ]

  lifecycle {
    prevent_destroy = false
  }
}

# Service Account, API Key and role bindings for the cluster admin
resource "confluent_service_account" "example_dedicated_sa_cluster_admin" {
  display_name = "${local.resource_prefix}_example_dedicated_sa_cluster_admin"
  description  = "Service Account mTLS Example Cluster Admin"
}

# An API key with Cluster Admin access. Required for provisioning the cluster-specific resources such as our topic
resource "confluent_api_key" "example_dedicated_api_key_sa_cluster_admin" {
  display_name = "${local.resource_prefix}_example_dedicated_api_key_sa_cluster_admin"
  description  = "Kafka API Key that is owned by '${local.resource_prefix}_example_dedicated_sa_cluster_admin' service account"
  owner {
    id          = confluent_service_account.example_dedicated_sa_cluster_admin.id
    api_version = confluent_service_account.example_dedicated_sa_cluster_admin.api_version
    kind        = confluent_service_account.example_dedicated_sa_cluster_admin.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = confluent_environment.myenv.id
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Assign the CloudClusterAdmin role to the cluster admin service account
resource "confluent_role_binding" "example_dedicated_role_binding_cluster_admin" {
  principal   = "User:${confluent_service_account.example_dedicated_sa_cluster_admin.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.dedicated.rbac_crn
  lifecycle {
    prevent_destroy = false
  }
  depends_on = [ aws_route.routes ]
}

# Service Account, API Key and role bindings for the producer
resource "confluent_service_account" "example_dedicated_sa_producer" {
  display_name = "${local.resource_prefix}_example_dedicated_sa_producer"
  description  = "Service Account mTLS Example Producer"
  depends_on = [ aws_route.routes ]
}

resource "confluent_api_key" "example_dedicated_api_key_producer" {
  display_name = "${local.resource_prefix}_example_dedicated_api_key_producer"
  description  = "Kafka API Key that is owned by '${local.resource_prefix}_example_dedicated_sa' service account"
  owner {
    id          = confluent_service_account.example_dedicated_sa_producer.id
    api_version = confluent_service_account.example_dedicated_sa_producer.api_version
    kind        = confluent_service_account.example_dedicated_sa_producer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = confluent_environment.myenv.id
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

# For role bindings such as DeveloperRead and DeveloperWrite at least a standard cluster type would be required. We use ACLs instead for basic clusters
resource "confluent_role_binding" "example_dedicated_role_binding_producer" {
  # Instaniciate this block only if the cluster type is NOT basic
  principal   = "User:${confluent_service_account.example_dedicated_sa_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.dedicated.rbac_crn}/kafka=${confluent_kafka_cluster.dedicated.id}/topic=${confluent_kafka_topic.example_dedicated_topic_test.topic_name}"
  lifecycle {
    prevent_destroy = false
  }
}

# Service Account, API Key and role bindings for the consumer
resource "confluent_service_account" "example_dedicated_sa_consumer" {
  display_name = "${local.resource_prefix}_example_dedicated_sa_consumer"
  description  = "Service Account mTLS Lambda Example Consumer"
  depends_on = [ aws_route.routes ]
}


resource "confluent_api_key" "example_dedicated_api_key_consumer" {
  display_name = "${local.resource_prefix}_example_dedicated_api_key_consumer"
  description  = "Kafka API Key that is owned by '${local.resource_prefix}_example_dedicated_sa' service account"
  owner {
    id          = confluent_service_account.example_dedicated_sa_consumer.id
    api_version = confluent_service_account.example_dedicated_sa_consumer.api_version
    kind        = confluent_service_account.example_dedicated_sa_consumer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = confluent_environment.myenv.id
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

# For role bindings such as DeveloperRead and DeveloperWrite at least a standard cluster type would be required. Let's use ACLs instead
resource "confluent_role_binding" "example_dedicated_role_binding_consumer" {
  # Instaniciate this block only if the cluster type is NOT basic
  principal   = "User:${confluent_service_account.example_dedicated_sa_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.dedicated.rbac_crn}/kafka=${confluent_kafka_cluster.dedicated.id}/topic=${confluent_kafka_topic.example_dedicated_topic_test.topic_name}"
  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_role_binding" "example_dedicated_role_binding_consumer_group" {
  # Instaniciate this block only if the cluster type is NOT basic
  principal   = "User:${confluent_service_account.example_dedicated_sa_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.dedicated.rbac_crn}/kafka=${confluent_kafka_cluster.dedicated.id}/group=${var.ccloud_cluster_consumer_group_prefix}*"
  lifecycle {
    prevent_destroy = false
  }
}

output "cluster_bootstrap_server" {
   value = confluent_kafka_cluster.dedicated.bootstrap_endpoint
}
output "cluster_rest_endpoint" {
    value = confluent_kafka_cluster.dedicated.rest_endpoint
}

# The next entries demonstrate how to output the generated API keys to the console even though they are considered to be sensitive data by Terraform
# Uncomment these lines if you want to generate that output
# output "cluster_api_key_admin" {
#     value = nonsensitive("Key: ${confluent_api_key.example_dedicated_api_key_sa_cluster_admin.id}\nSecret: ${confluent_api_key.example_dedicated_api_key_sa_cluster_admin.secret}")
# }

# output "cluster_api_key_producer" {
#     value = nonsensitive("Key: ${confluent_api_key.example_dedicated_api_key_producer.id}\nSecret: ${confluent_api_key.example_dedicated_api_key_producer.secret}")
# }

# output "cluster_api_key_consumer" {
#     value = nonsensitive("Key: ${confluent_api_key.example_dedicated_api_key_consumer.id}\nSecret: ${confluent_api_key.example_dedicated_api_key_consumer.secret}")
# }

# Generate console client configuration files for testing in subfolder "generated/client-configs"
# PLEASE NOTE THAT THESE FILES CONTAIN SENSITIVE CREDENTIALS
resource "local_sensitive_file" "client_config_files" {
  # Do not generate any files if var.ccloud_cluster_generate_client_config_files is false
  for_each = var.ccloud_cluster_generate_client_config_files ? {
    "admin" = confluent_api_key.example_dedicated_api_key_sa_cluster_admin,
    "producer" = confluent_api_key.example_dedicated_api_key_producer,
    "consumer" = confluent_api_key.example_dedicated_api_key_consumer} : {}

  content = templatefile("${path.module}/templates/client.conf.tpl",
  {
    client_name = "${each.key}"
    cluster_bootstrap_server = trimprefix("${confluent_kafka_cluster.dedicated.bootstrap_endpoint}", "SASL_SSL://")
    api_key = "${each.value.id}"
    api_secret = "${each.value.secret}"
    topic = var.ccloud_cluster_topic
    consumer_group_prefix = var.ccloud_cluster_consumer_group_prefix
  }
  )
  filename = "${var.generated_files_path}/client-${each.key}.conf"
}
