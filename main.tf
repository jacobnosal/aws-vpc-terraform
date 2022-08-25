resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "demo_vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "10.0.1.0/24_${data.aws_availability_zones.available.names[0]}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "10.0.2.0/24_${data.aws_availability_zones.available.names[1]}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "demo_internet_gateway"
  }
}

resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "demo_public_subnet_route_table"
  }
}

resource "aws_route" "route_public_internet" {
  route_table_id         = aws_route_table.public_subnet_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "internet_gateway_to_public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_subnet_route_table.id
}

resource "aws_security_group" "web_dmz_security_group" {
  name   = "web_dmz_security_group"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "web_dmz_security_group"
  }
}

resource "aws_security_group_rule" "allow_80" {
  description       = "Ingress on port 80."
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_dmz_security_group.id
}

resource "aws_security_group_rule" "allow_443" {
  description       = "Ingress on port 443."
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_dmz_security_group.id
}

resource "aws_security_group_rule" "allow_22" {
  description       = "Ingress on port 22."
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_dmz_security_group.id
}

resource "aws_security_group_rule" "allow_outbound_internet" {
  description       = "Egress to public internet."
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_dmz_security_group.id
}

data "aws_ami" "nginx" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["amzn_nginx-*"]
  }
}

resource "aws_ebs_volume" "public_vm_ebs_volume_0" {
  availability_zone = aws_instance.public_vm_0.availability_zone
  encrypted         = true
  size              = 16

  tags = {
    Name = "public_vm_ebs_volume_0"
  }
}

resource "aws_instance" "public_vm_0" {
  ami                         = data.aws_ami.nginx.image_id
  instance_type               = "t2.micro"
  availability_zone           = data.aws_availability_zones.available.names[0]
  key_name                    = aws_key_pair.public_vm_0_key_pair.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_dmz_security_group.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = {
    Name = "public_vm_0"
  }
}

resource "aws_volume_attachment" "public_vm_ebs_volume_0_attachment" {
  device_name                    = "/dev/sdh"
  volume_id                      = aws_ebs_volume.public_vm_ebs_volume_0.id
  instance_id                    = aws_instance.public_vm_0.id
  stop_instance_before_detaching = true
}

resource "tls_private_key" "public_vm_0" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "public_vm_0_key_pair" {
  key_name   = "public_vm_0"
  public_key = tls_private_key.public_vm_0.public_key_openssh
}

# Private VM configurations
resource "aws_key_pair" "private_vm_0_key_pair" {
  key_name   = "private_vm_0"
  public_key = tls_private_key.public_vm_0.public_key_openssh
}

resource "aws_instance" "private_vm_0" {
  ami                    = "ami-0cea098ed2ac54925"
  instance_type          = "t2.micro"
  availability_zone      = data.aws_availability_zones.available.names[1]
  key_name               = aws_key_pair.private_vm_0_key_pair.key_name
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.db_tier_security_group.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = {
    Name = "private_vm_0"
  }
}

resource "aws_security_group" "db_tier_security_group" {
  name   = "db_tier_security_group"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "db_tier_security_group"
  }
}

resource "aws_security_group_rule" "all_icmp_v4" {
  description       = "All ICMP v4"
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["10.0.1.0/24"]
  security_group_id = aws_security_group.db_tier_security_group.id
}

resource "aws_security_group_rule" "db_tier_allow_80" {
  description       = "Ingress on port 80."
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["10.0.1.0/24"]
  security_group_id = aws_security_group.db_tier_security_group.id
}

resource "aws_security_group_rule" "db_tier_allow_22" {
  description       = "Ingress on port 22."
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["10.0.1.0/24"]
  security_group_id = aws_security_group.db_tier_security_group.id
}

resource "aws_security_group_rule" "allow_3306" {
  description       = "Ingress on port 3306."
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["10.0.1.0/24"]
  security_group_id = aws_security_group.db_tier_security_group.id
}

resource "aws_security_group_rule" "adb_tier_llow_outbound_internet" {
  description       = "Egress to public internet."
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db_tier_security_group.id
}