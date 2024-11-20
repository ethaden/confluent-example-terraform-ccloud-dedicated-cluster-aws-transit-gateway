# Example for using a Confluent Cloud dedicated cluster on AWS with a Transit Gateway
This terraform configuration show how to set up a Confluent Cloud dedicated cluster on AWS with Transit Gateway.

## Precondition
Obviously, you need to have an AWS account with proper credentials set up.

## Usage

### Terraform Setup
First you need to copy `terraform.tfvars-template` to local file `terraform.tfvars` and customize it.

Then you just run terraform and look at the plan (optional step):

```bash
terraform plan
```

Execute the plan by running:

```bash
terraform apply
```

You can delete the generated resources by running:

```bash
terraform destroy
```

## DISCLAIMER
THIS CONFIGURATION IS MEANT FOR TESTING ONLY AND NOT FOR PRODUCTION. PLEASE CHECK THE [LICENSE](LICENSE) FOR FURTHER INFORMATION.
