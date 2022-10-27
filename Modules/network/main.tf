# --- network/main.tf

#VPC resource
resource "aws_vpc" "projectVPC" {
  cidr_block = var.vpc_cidr
}

#Public subnets resource
resource "aws_subnet" "pubsub" {
  
  vpc_id                  = aws_vpc.projectVPC.id
  count                   = length(var.azs)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  cidr_block              = var.pubsubCIDRblocks[count.index]
}

#Private subnets resource
resource "aws_subnet" "privsub" {
  vpc_id                  = aws_vpc.projectVPC.id
  count                   = length(var.azs)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false
  cidr_block              = var.privsubCIDRblocks[count.index]
  tags = {
    "Private" = "True"
  }
}

#Internet gateway
resource "aws_internet_gateway" "projectgateway" {
  vpc_id = aws_vpc.projectVPC.id
}

#Public security group
resource "aws_security_group" "public_SG" {
  name   = "public_SG"
  vpc_id = aws_vpc.projectVPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Private security group
resource "aws_security_group" "private_SG" {
  name   = "private_SG"
  vpc_id = aws_vpc.projectVPC.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_SG.id]
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_SG.id]
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#Create public and private subnet route tables
resource "aws_route_table" "publicroute" {
  vpc_id = aws_vpc.projectVPC.id

  route {
    gateway_id = aws_internet_gateway.projectgateway.id
    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_route_table" "privateroute" {
  vpc_id = aws_vpc.projectVPC.id

  route {
    gateway_id = aws_internet_gateway.projectgateway.id
    cidr_block = "0.0.0.0/0"
  }
}

#Route table associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.pubsub)
  subnet_id      = aws_subnet.pubsub[count.index].id
  route_table_id = aws_route_table.publicroute.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.privsub)
  subnet_id      = aws_subnet.privsub[count.index].id
  route_table_id = aws_route_table.privateroute.id
}

resource "aws_eip" "elastic_ip" {
  vpc        = true
  depends_on = [aws_internet_gateway.projectgateway]
}

resource "aws_nat_gateway" "project_nat" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.pubsub[0].id

  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.projectgateway]
}