###  core  ###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.31.0"
    }
  }
}


resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr[0]
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.name}-vpc-${terraform.workspace}"
  }

}


resource "aws_internet_gateway" "gw" {
  vpc_id = (aws_vpc.vpc.id)

  tags = {
    Name        = "${var.name}-igw-${terraform.workspace}"
  }
}


resource "aws_subnet" "private" {
  vpc_id            = (aws_vpc.vpc.id)
  cidr_block        = var.cidr-subnets[0]
  availability_zone = "us-east-1a"

  tags = {
    Name        = "${var.name}-private-1a-${terraform.workspace}"
  }
}


resource "aws_subnet" "private1" {
  vpc_id            = (aws_vpc.vpc.id)
  cidr_block        = var.cidr-subnets[1]
  availability_zone = "us-east-1b"

  tags = {
    Name        = "${var.name}-private-1b-${terraform.workspace}"
  }
}




resource "aws_subnet" "public" {
  vpc_id            = (aws_vpc.vpc.id)
  cidr_block        = var.cidr-subnets[2]
  availability_zone = "us-east-1a"

  tags = {
    Name        = "${var.name}-public-1a-${terraform.workspace}"
  }
}


resource "aws_subnet" "public1" {
  vpc_id            = (aws_vpc.vpc.id)
  cidr_block        = var.cidr-subnets[3]
  availability_zone = "us-east-1b"

  tags = {
    Name        = "${var.name}-public-1b-${terraform.workspace}"
  }
}



### modules ###

module "route" {
  source          = "./modules/route"
  vpc_id          = (aws_vpc.vpc.id)
  gateway_id      = (aws_internet_gateway.gw.id)
  environment     = terraform.workspace
  name            = var.name
  subnet_id_pub1a = (aws_subnet.public.id)
  subnet_id_pub1b = (aws_subnet.public1.id)
  subnet_id1a     = (aws_subnet.private.id)
  subnet_id1b     = (aws_subnet.private1.id)

}

module "roles" {
  source = "./modules/roles"
  environment     = terraform.workspace
}


module "ecs" {
  source          = "./modules/ecs"
  vpc_id          = (aws_vpc.vpc.id)
  name            = var.name
  environment     = terraform.workspace
  subnet_id_pub1a = (aws_subnet.public.id)
  subnet_id_pub1b = (aws_subnet.public1.id)
  subnet_id1a     = (aws_subnet.private.id)
  subnet_id1b     = (aws_subnet.private1.id)
}

