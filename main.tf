locals {
  name = "lab-09"
}
# Creating vpc
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${local.name}-vpc"
  }
}

# creating public subnet
resource "aws_subnet" "subnet-pub" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "${local.name}-subnet-pub"
  }
}

# creating private subnet
resource "aws_subnet" "subnet-pri" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "${local.name}-subnet-pri"
  }
}

# Creating igw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.name}-igw"
  }
}

# Creating Natgateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.subnet-pub.id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "${local.name}-gw NAT"
  }
}

# creating eip
resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = "${local.name}-eip"
  }
}

# Creating public route table
resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${local.name}-pub-rt"
  }
}

# Creating route table association for public subnet
resource "aws_route_table_association" "pub-rt" {
  subnet_id      = aws_subnet.subnet-pub.id
  route_table_id = aws_route_table.pub-rt.id
}

# Creating private route table
resource "aws_route_table" "pri-rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }
  tags = {
    Name = "${local.name}-pri-rt"
  }
}

# Creating route table association for private subnet
resource "aws_route_table_association" "pri-rt" {
  subnet_id      = aws_subnet.subnet-pri.id
  route_table_id = aws_route_table.pri-rt.id
}

# Creating ansible security group
resource "aws_security_group" "ansible-sg" {
  vpc_id      = aws_vpc.vpc.id
  description = "This is my ansible security group"
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.name}-ansible-sg"
  }
}

# Creating security group for managed node
resource "aws_security_group" "managed-node-sg" {
  vpc_id      = aws_vpc.vpc.id
  description = "This is my managed-node security group"
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.name}-managed-node-sg"
  }
}

# Creating key pair
resource "aws_key_pair" "key-pair" {
  key_name   = "ansible-key"
  public_key = file("./ansible-key.pub")
}

# Creating ansible instance
resource "aws_instance" "ansible" {
  ami                         = "ami-0c38b837cd80f13bb" # ubuntu ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet-pub.id
  key_name                    = aws_key_pair.key-pair.id
  vpc_security_group_ids      = [aws_security_group.ansible-sg.id]
  associate_public_ip_address = true
  user_data                   = file("./user-data.sh")

  tags = {
    Name = "${local.name}-ansible-node"
  }
}

# Creating managed node 1 instance
resource "aws_instance" "redhat" {
  ami                         = "ami-07d4917b6f95f5c2a" # redhat ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet-pub.id
  key_name                    = aws_key_pair.key-pair.id
  vpc_security_group_ids      = [aws_security_group.managed-node-sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "${local.name}-redhat"
  }
}

# Creating managed node 2 instance
resource "aws_instance" "ubuntu" {
  ami                         = "ami-0c38b837cd80f13bb" # ubuntu ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet-pub.id
  key_name                    = aws_key_pair.key-pair.id
  vpc_security_group_ids      = [aws_security_group.managed-node-sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "${local.name}-ubuntu"
  }
}