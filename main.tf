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

# Security groups

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

# EC2 instance

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
    source      = "server.env"
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

# Lambda roles

resource "aws_iam_role" "StartServerLambdaRole" {
  name = "StartServerLambdaRole"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role" "StopServerLambdaRole" {
  name = "StopServerLambdaRole"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "LambdaStartEC2Role" {
  name = "LambdaStartEC2Role"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement = [
      {
        Action   = "ec2:StartInstances"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "LambdaStopEC2Role" {
  name = "LambdaStopEC2Role"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement = [
      {
        Action   = "ec2:StopInstances"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_policy" "LambdaBasicExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "StartLambdaBasicExec" {
  role       = aws_iam_role.StartServerLambdaRole.name
  policy_arn = data.aws_iam_policy.LambdaBasicExecutionRole.arn
}

resource "aws_iam_role_policy_attachment" "StartLambdaStartEC2" {
  role       = aws_iam_role.StartServerLambdaRole.name
  policy_arn = resource.aws_iam_policy.LambdaStartEC2Role.arn
}

resource "aws_iam_role_policy_attachment" "StopLambdaBasicExec" {
  role       = aws_iam_role.StopServerLambdaRole.name
  policy_arn = data.aws_iam_policy.LambdaBasicExecutionRole.arn
}

resource "aws_iam_role_policy_attachment" "StopLambdaStopEC2" {
  role       = aws_iam_role.StopServerLambdaRole.name
  policy_arn = resource.aws_iam_policy.LambdaStopEC2Role.arn
}

# Lambdas

data "archive_file" "start_server_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda/startServer/index.mjs"
  output_path = "${path.module}/src/lambda/dist/startServer.zip"
}

data "archive_file" "stop_server_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda/stopServer/index.mjs"
  output_path = "${path.module}/src/lambda/dist/stopServer.zip"
}

resource "aws_lambda_function" "start_server_lambda" {
  function_name = "Start_Valheim_server"

  filename = "${path.module}/src/lambda/dist/startServer.zip"
  handler  = "index.handler"
  runtime  = "nodejs20.x"

  role             = aws_iam_role.StartServerLambdaRole.arn
  source_code_hash = data.archive_file.start_server_zip.output_base64sha256

  depends_on = [aws_instance.server]

  environment {
    variables = {
      REGION             = var.region
      SERVER_INSTANCE_ID = aws_instance.server.id
    }
  }
}

resource "aws_lambda_function" "stop_server_lambda" {
  function_name = "Stop_Valheim_server"

  filename = "${path.module}/src/lambda/dist/stopServer.zip"
  handler  = "index.handler"
  runtime  = "nodejs20.x"

  role             = aws_iam_role.StopServerLambdaRole.arn
  source_code_hash = data.archive_file.start_server_zip.output_base64sha256

  depends_on = [aws_instance.server]

  environment {
    variables = {
      REGION             = var.region
      SERVER_INSTANCE_ID = aws_instance.server.id
    }
  }
}
