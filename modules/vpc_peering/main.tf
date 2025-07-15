resource "aws_vpc_peering_connection" "peer" {
  vpc_id       = var.vpc_id_requester
  peer_vpc_id  = var.vpc_id_accepter
  auto_accept  = true

  tags = merge(var.tags, {
    Name = "peer-${var.name}"
  })
}

resource "aws_route" "requester_to_accepter" {
  count                     = length(var.requester_private_subnet_route_table_ids)
  route_table_id            = var.requester_private_subnet_route_table_ids[count.index]
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "accepter_to_requester" {
  count                     = length(var.accepter_private_subnet_route_table_ids)
  route_table_id            = var.accepter_private_subnet_route_table_ids[count.index]
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
