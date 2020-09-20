terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


variable  "aws_access_key" { }
variable  "aws_secret_key" { }

variable  "aws_region" { 
    default = "us-east-1"
}
variable  "aws_instance_type" { 
    default = "t2.micro"
}

provider "aws" {
  profile = "default"
  aws_access_key= "var.aws_access_key"
  aws_secret_key = "var.aws_secret_key"
  region  = "var.aws_region"
}

# get ec2 data source from the provider

data "aws_ami" "alx"{
    most_recent = true
    owners = ["amazon"]
    filters{}
}

resource "aws_instance" "example" {
  ami           = "data.aws_ami.alx.id"
  instance_type = "var.aws_instance_type"
}

output "aws_public_ip"{
    value = "aws_instance.ex.public_dns"
}
 
# Create a VPC
# resource "aws_vpc" "example" {
#   cidr_block = "10.0.0.0/16"
# }