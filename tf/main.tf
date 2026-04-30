terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.42.0"
    }
  }
}

provider "aws" {
    region = "eu-west-3"
}

data "aws_ami" "nixos_x86_64" {
  owners = ["427812963091"]
  most_recent = true

  filter {
    name   = "name"
    values = ["nixos/25.11*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "nixos_arm64" {
  owners = ["427812963091"]
  most_recent = true

  filter {
    name   = "name"
    values = ["nixos/25.11*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "aws_key_pair" "jtremesay" {
  key_name   = "jtremesay"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "weave" {
  name = "weave-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "weave" {
  ami                    = data.aws_ami.nixos_x86_64.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.jtremesay.key_name
  vpc_security_group_ids = [aws_security_group.weave.id]
  associate_public_ip_address = true
}

output "weave_dns" {
  value = aws_instance.weave.public_dns
}