resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "SSM bastion ${var.name}: egress only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}

# The SSM agent needs 443 to Systems Manager through NAT.
#trivy:ignore:AVD-AWS-0104
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.this.id
  description       = "HTTPS to Systems Manager through NAT"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443

  tags = var.tags
}

locals {
  extra_egress_rules = var.egress_tcp_ports == null ? {
    for cidr in var.egress_cidr_blocks : cidr => { cidr = cidr, protocol = "-1", port = null }
    } : {
    for pair in setproduct(var.egress_cidr_blocks, var.egress_tcp_ports) : "${pair[0]}/${pair[1]}" => { cidr = pair[0], protocol = "tcp", port = pair[1] }
  }
}

resource "aws_vpc_security_group_egress_rule" "extra" {
  for_each = local.extra_egress_rules

  security_group_id = aws_security_group.this.id
  description       = each.value.port == null ? "Bastion egress to ${each.value.cidr}" : "Bastion egress to ${each.value.cidr} on ${each.value.port}"
  cidr_ipv4         = each.value.cidr
  ip_protocol       = each.value.protocol
  from_port         = each.value.port
  to_port           = each.value.port

  tags = var.tags
}
