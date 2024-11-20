data "aws_vpc" "vpc" {
    id = var.vpc_id
}

data "aws_subnets" "vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_ec2_transit_gateway" "tgw" {
  description = "${var.resource_prefix}tgw"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_vpc_attach" {
  subnet_ids         = toset(data.aws_subnets.vpc_subnets.ids)
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = var.vpc_id
}

resource "aws_ec2_transit_gateway_connect" "tgw_connect" {
  transport_attachment_id = aws_ec2_transit_gateway_vpc_attachment.tgw_vpc_attach.id
  transit_gateway_id      = aws_ec2_transit_gateway.tgw.id
}

