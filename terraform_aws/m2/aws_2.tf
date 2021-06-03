# adding vpc resource 

# add vpc --> resource "aws_vpc" "vpc" {}
# add internet gateway and atatch to vpc --> resource "aws_internet_gateway" "igw" {}
# create subnet <range of ip address> --> resource "aws_subnet" "subnet1" {}
# create route table --> resource "aws_route_table" "rtb" {}
# create route table association --> resource "aws_route_table_association" "rta-subnet1" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# variables
variable "aws_access_key" {}
variable "aws_secret_key" {}

# key name refers to a key pair that exits with in aws, so that we can ssh into the instance once its created. 
variable "key_name" {}
# path to the private key that corresponds to the key pair thats in aws.
variable "private_key_path" {}
# variable to aws region
variable "aws_region" {
  default = "us-east-1"
}
# variable to define tyoe of instance
variable "aws_instance_type" {
  default = "t2.micro"
}

variable "network_address_space" {
  default = "10.1.0.0/16"
}

variable "subnet1_address_space" {
  default = "10.1.0.0/24"
}


provider "aws" {
  # profile        = "default"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}


# DATA section

#data "aws_availabilty_zones" "available" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# pulling the data from the provider
# we need get the latest aws linux ami for the ec2 instace. so we need to get the latest version 
# of AMI image. below 
data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# resources section


# networking #

# this uses the default vpc. It will not delete it or destroy
resource "aws_vpc" "vpc" {
  cidr_block           = var.network_address_space
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet1" {
  cidr_block              = var.subnet1_address_space
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rt-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt.id
}


resource "aws_security_group" "allow_ssh" {
  name        = "nginx_demo"
  description = "allow ports for nginx demo"
  vpc_id      = aws_vpc.vpc.id
  # ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # nginix web server
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # traffic to go the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "nginix" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.subnet1.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "echo '<html><head><title> Blue Teasm Server </title></head></html>'"
    ]
  }
}

# output
output "aws_instance_public_dns" {
  value = aws_instance.nginix.public_dns
}

# Create a VPC
# resource "aws_vpc" "example" {
#   cidr_block = "10.0.0.0/16"
# }