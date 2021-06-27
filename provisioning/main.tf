terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "ap-southeast-1"
}

resource "aws_instance" "rmf_fullstack" {
  ami           = "ami-0d058fe428540cd89"
  instance_type = "c5.2xlarge"
  vpc_security_group_ids = [aws_security_group.rmf_fullstack.id]
  subnet_id = aws_subnet.rmf_fullstack.id
  key_name = "rmf_fullstack"
  ebs_block_device{
    device_name = "/dev/sda1"
    volume_size = 64
    volume_type = "gp2"
  }

  tags = {
    Name = "RMF Fullstack"
  }
}

resource "aws_eip" "eip" {
  vpc = true
  instance = aws_instance.rmf_fullstack.id
  tags = {
    Name = "RMF Fullstack"
  }
}

resource "aws_vpc" "rmf_fullstack" {
  cidr_block = "192.168.0.0/16"  
  tags = {
    Name = "RMF Fullstack"
  }
}

resource "aws_internet_gateway" "rmf_fullstack" {
  vpc_id = aws_vpc.rmf_fullstack.id
  tags = {
    Name = "RMF Fullstack"
  }
}
 
resource "aws_route" "outbound_via_igw" {
  route_table_id = aws_vpc.rmf_fullstack.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.rmf_fullstack.id
}


resource "aws_subnet" "rmf_fullstack" {
  vpc_id = aws_vpc.rmf_fullstack.id
  cidr_block = "192.168.29.0/24" 
  map_public_ip_on_launch = true
  tags = {
    Name = "RMF Fullstack"
  }
}

resource "aws_security_group" "rmf_fullstack" {
  name = "rmf_fullstack_network"
  description = "Security group for rmf_fullstack"
  vpc_id = aws_vpc.rmf_fullstack.id

  ingress { 
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { 
    description = "https"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { 
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { 
    description = "Wireguard"
    from_port = 58120
    to_port = 58120
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "RMF Fullstack"
  }
}

output "aws_public_ip" {
  value = aws_eip.eip.public_ip
}
