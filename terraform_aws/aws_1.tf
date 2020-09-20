terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# aws access keys
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

provider "aws" {
  profile        = "default"
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  region         = var.aws_region
}


# DATA section

# pulling the data from the provider
# we need get the latest aws linux ami for the ec2 instace. so we need to get the latest version 
# of AMI image. below 
data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]
  filters {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }
  filters {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filters {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# resources section


# this uses the default vpc. It will not delete it or destroy
resource "aws_default_vpc" "default" {
}

resource "aws_security_group" "allow_ssh" {
  name        = "nginx_demo"
  description = "allow ports for nginx demo"
  vpc_id      = aws_default_vpc.default.id
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
  instance_type          = "var.aws_instance_type"
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
      "sudo service nginx start"
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