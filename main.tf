terraform {
  required_version = "~>1.9.0"
}

provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      Terraform = "True"
      Stack     = "Valheim"
    }
  }
}

resource "aws_security_group" "server_sg" {
  name        = "Valheim server SG"
  description = "Set of inbound and outbound rules for the server EC2 instance"
}

resource "aws_vpc_security_group_ingress_rule" "allow_inbound_ssh" {
  description       = "Allow inbound SSH connections"
  security_group_id = aws_security_group.server_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_inbound_http" {
  description       = "Allow inbound HTTP connections"
  security_group_id = aws_security_group.server_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_inbound_udp" {
  description       = "Allow inbound UDP connections for the valheim server"
  security_group_id = aws_security_group.server_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "udp"
  from_port   = 2456
  to_port     = 2458
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_all" {
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.server_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

resource "aws_instance" "server" {
  ami             = var.server_ami
  instance_type   = var.server_ec2_type
  security_groups = [aws_security_group.server_sg.name]
  key_name        = "vh"

  tags = {
    Name = "Valheim server"
  }

  provisioner "file" {
    source      = "bootstrap/${var.bootstrap_script}"
    destination = "/home/${var.ec2_user}/${var.bootstrap_script}"
  }

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/${var.ec2_user}/docker-compose.yml"
  }

  provisioner "file" {
    source = "server.env"
    destination = "/home/${var.ec2_user}/server.env"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.ec2_user}/${var.bootstrap_script}",
      "/home/${var.ec2_user}/${var.bootstrap_script}"
    ]
  }

  connection {
    type        = "ssh"
    user        = var.ec2_user
    private_key = file(".ssh/vh.pem")
    host        = self.public_ip
  }
}
