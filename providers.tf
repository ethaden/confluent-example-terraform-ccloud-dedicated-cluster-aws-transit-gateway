terraform {
  required_providers {
    confluent = {
      source = "confluentinc/confluent"
      #version = "1.25.0"
    }
  }
}
provider "aws" {
    region = var.aws_region

    default_tags {
      tags = local.confluent_tags
    }
}

# Option #2: Manage a single Kafka cluster in the same Terraform workspace
# See https://github.com/confluentinc/terraform-provider-confluent/tree/master/examples/configurations/managing-single-kafka-cluster for more details
provider "confluent" {
  # Specifying Cloud API Keys is still necessary for now when managing confluent_kafka_acl
  cloud_api_key       = local.confluent_creds.api_key    # optionally use CONFLUENT_CLOUD_API_KEY env var
  cloud_api_secret    = local.confluent_creds.api_secret # optionally use CONFLUENT_CLOUD_API_SECRET env var
  #kafka_id            = var.kafka_id                   # optionally use KAFKA_ID env var
  #kafka_rest_endpoint = var.kafka_rest_endpoint        # optionally use KAFKA_REST_ENDPOINT env var
  #kafka_api_key       = var.kafka_api_key              # optionally use KAFKA_API_KEY env var
  #kafka_api_secret    = var.kafka_api_secret           # optionally use KAFKA_API_SECRET env var
}
# Manage topics, ACLs, etc.

# Option #2: Manage a single Schema Registry cluster in the same Terraform workspace
# See https://github.com/confluentinc/terraform-provider-confluent/tree/master/examples/configurations/managing-single-schema-registry-cluster for more details
#provider "confluent" {
#  schema_registry_id            = var.schema_registry_id            # optionally use SCHEMA_REGISTRY_ID env var
#  schema_registry_rest_endpoint = var.schema_registry_rest_endpoint # optionally use SCHEMA_REGISTRY_REST_ENDPOINT env var
#  schema_registry_api_key       = var.schema_registry_api_key       # optionally use SCHEMA_REGISTRY_API_KEY env var
#  schema_registry_api_secret    = var.schema_registry_api_secret    # optionally use SCHEMA_REGISTRY_API_SECRET env var
#}

resource "random_id" "id" {
  byte_length = 4
}
