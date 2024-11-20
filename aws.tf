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

  depends_on = [
    aws_ram_resource_association.tgw_share_assoc,
  ]
}

# Do not use
#resource "aws_ec2_transit_gateway_connect" "tgw_connect" {
#  transport_attachment_id = aws_ec2_transit_gateway_vpc_attachment.tgw_vpc_attach.id
#  transit_gateway_id      = aws_ec2_transit_gateway.tgw.id
#}

resource "aws_ram_resource_share" "tgw_share" {

  name =  "${var.resource_prefix}tgw_ram"
  allow_external_principals = true
}

# Share the transit gateway...
resource "aws_ram_resource_association" "tgw_share_assoc" {

  resource_arn       = aws_ec2_transit_gateway.tgw.arn
  resource_share_arn = aws_ram_resource_share.tgw_share.id
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "tgw_accepter" {

  transit_gateway_attachment_id = confluent_transit_gateway_attachment.confluent_tgw_attach.aws[0].transit_gateway_attachment_id

  tags = {
    Name = "${var.resource_prefix}tgw_accepter"
    Side = "Accepter"
  }
}
