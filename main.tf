data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "demo_vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "demo_public_subnet"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "demo_internet_gateway"
  }
}

resource "aws_route_table" "internet_gateway_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet_gateway_route_table"
  }
}

resource "aws_route" "outbound_public_internet" {
    route_table_id = aws_route_table.internet_gateway_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "internet_gateway_to_public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.internet_gateway_route_table.id
}

resource "aws_security_group" "security_group" {
  name   = "demo_security_group"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "demo_security_group"
  }
}

resource "aws_security_group_rule" "allow_80" {
  description       = "Ingress on port 80."
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "allow_443" {
  description       = "Ingress on port 443."
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "demo_private_subnet"
  }
}

resource "aws_eip" "nat_gateway_ip" {
  vpc = true

  tags = {
    Name = "nat_gateway_ip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway_ip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "demo_nat_gateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table" "private_subnet_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private_subnet_route_table"
  }
}

resource "aws_route" "outbound_nat_gateway" {
    route_table_id = aws_route_table.private_subnet_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "outbound_nat_gateway_to_private_subnet_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_subnet_route_table.id
}