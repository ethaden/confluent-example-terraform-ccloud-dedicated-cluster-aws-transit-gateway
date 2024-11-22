variable "tf_last_updated" {
    type = string
    default = ""
    description = "Set this value to fix the tag holding the date of the last update"
}

# Recommendation: Overwrite the default in tfvars or by specify an environment variable TF_VAR_aws_region
variable "aws_region" {
    type = string
    default = "eu-central-1"
    description = "The AWS region to be used"
}

variable "purpose" {
    type = string
    default = "Testing"
    description = "The purpose of this configuration, used e.g. as tags for AWS resources"
}

variable "owner" {
    type = string
    default = ""
    description = "All resources are tagged with an owner tag. If none is provided in this variable, a useful value is derived from the environment"
}

variable "username" {
    type = string
    default = ""
    description = "Username, used to define local.username if set here. Otherwise, the logged in username is used."
}

# The validator uses a regular expression for valid email addresses (but NOT complete with respect to RFC 5322)
variable "owner_email" {
    type = string
    default = ""
    description = "All resources are tagged with an owner_email tag. If none is provided in this variable, a useful value is derived from the environment"
    validation {
        condition = anytrue([
            var.owner_email=="",
            can(regex("^[a-zA-Z0-9_.+-]+@([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9]+)*\\.)+[a-zA-Z]+$", var.owner_email))
        ])
        error_message = "Please specify a valid email address for variable owner_email or leave it empty"
    }
}

variable "owner_fullname" {
    type = string
    default = ""
    description = "All resources are tagged with an owner_fullname tag. If none is provided in this variable, a useful value is derived from the environment"
}

variable "ssh_key_name" {
    type = string
    description = "Existing (in AWS) public SSH key to use"
}

variable "resource_prefix" {
    type = string
    default = ""
    description = "This string will be used as prefix for generated resources"
}

variable "vpc_id" {
    type = string
    description = "The Id of the VPC to connect the transit gateway to"
}

variable "generated_files_path" {
    description = "The main path to write generated files to"
    type = string
    default = "./generated"
}

variable "ccloud_cluster_topic" {
    type = string
    default = "test"
    description = "The name of the Kafka topic to create and to subscribe to"
}

variable "ccloud_cluster_consumer_group_prefix" {
    type = string
    default = "client-"
    description = "The name of the Kafka consumer group prefix to grant access to the Kafka consumer"
}

variable "ccloud_cluster_generate_client_config_files" {
    type = bool
    default = false
    description = "Set to true if you want to generate client configs with the created API keys under subfolder \"generated/client-configs\""
}

variable "ccloud_create_api_keys" {
    type = bool
    default = false
    description = "If set to true, creates api keys and roles"
}

variable "hosted_zone_domain" {
    type = string
    default = "example-confluent-dedicated-cluster-aws-tgw.local"
    description = "The domain for the example hosted zone"
}


# variable "db_password" {
#   description = "RDS root user password"
#   type        = string
#   sensitive   = true
# }

# variable "db_identifier" {
#   type        = string
#   default = "confluentexmampleawstransitgateway"
#   description = "Identifier of the database"
# }

variable "s3_bucket_name" {
    type = string
    default = "confluentexmampleawstransitgateway"
    description = "Identifier of the S3 bucket to be created (only lowercase alphanumeric characters and hyphens allowed!)"
}

variable "database_instance_type" {
    type = string
    default = "t2.micro"
    description = "The type of the database EC2 instance"
}
