resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "SSM bastion ${var.name}: egress only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.this.id
  description       = "HTTPS to Systems Manager through NAT"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "extra" {
  for_each = toset(var.egress_cidr_blocks)

  security_group_id = aws_security_group.this.id
  description       = "Bastion egress to ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "-1"

  tags = var.tags
}
