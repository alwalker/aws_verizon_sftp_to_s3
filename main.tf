provider "aws" {
  region     = "us-west-2"
}
terraform {
  backend "s3" {
    bucket = "terraform"
    key    = "sftp2s3"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = "terraform"
    key    = "facenet"
    region = "us-east-1"
  }
}

###############################################################################
#                           Security Groups                                   #
###############################################################################
resource "aws_security_group" "server" {
  name        = "${var.app_name}-server"
  vpc_id      = "vpc-"
  description = "Allow non standard SSH port in from world"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22 #57333
    to_port     = 22 #57333
    protocol    = "tcp"    
    #security_groups = [aws_security_group.test-server.id]
    cidr_blocks     = ["0.0.0.0/0"]
  }
  #iperf
  # ingress {
  #   from_port   = 5533
  #   to_port     = 5533
  #   protocol    = "tcp"
  #   cidr_blocks     = ["0.0.0.0/0"]
  # }

  tags = {
    Name = "${var.app_name}-app"
  }
}

resource "aws_security_group" "test-server" {
  name        = "${var.app_name}-test-server"
  vpc_id      = "vpc-"
  description = "Allow non standard SSH port in from world"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22 #57333
    to_port     = 22 #57333
    protocol    = "tcp"
    cidr_blocks     = ["/32"]
  }
}

###############################################################################
#                              Server Policies                                #
###############################################################################
resource "aws_iam_role" "server" {
  name = var.app_name
  description = "Allows EC2 tasks to do the things"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
data "template_file" "server-policies" {
    template = "${file("policies/server.json")}"

    vars = {
        b1 = ""
        b2 = ""
    }
}
resource "aws_iam_policy" "server" {
  name = "${var.app_name}-server"
  description = "Grant ${var.app_name} permisions to do the things"
  policy = data.template_file.server-policies.rendered
}
resource "aws_iam_role_policy_attachment" "server" {
    role       = aws_iam_role.server.name
    policy_arn = aws_iam_policy.server.arn
}
# resource "aws_iam_role_policy_attachment" "cloudwatchagent" {
#     role       = aws_iam_role.server.name
#     policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
# }
resource "aws_iam_instance_profile" "server" {
  name = var.app_name
  role = aws_iam_role.server.id
}

###############################################################################
#                                 Server                                      #
###############################################################################
data "aws_ami" "sftp2s3-image" {
  most_recent = true

  filter {
    name   = "name"
    values = ["sftp2s3-*"]
  }

  owners = [""]
}
resource "aws_key_pair" "admin" {
  key_name   = "${var.app_name}-admin-key"
  public_key = "ssh-rsa"
}
resource "aws_instance" "server" {
  ami           = data.aws_ami.sftp2s3-image.id
  instance_type = "t3.medium"
  vpc_security_group_ids = [aws_security_group.server.id]
  subnet_id = "subnet-"
  iam_instance_profile = aws_iam_instance_profile.server.id
  key_name = aws_key_pair.admin.key_name

  tags = {
    Name = "SFTP2S3"
  }
}
resource "aws_instance" "test-server" {
  ami           = data.aws_ami.sftp2s3-image.id
  instance_type = "t3a.nano"
  vpc_security_group_ids = [aws_security_group.test-server.id]
  subnet_id = "subnet-"
  associate_public_ip_address = true
  key_name = aws_key_pair.admin.key_name

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "SFTP2S3"
  }
}
resource "aws_eip" "carrier-ip" {
  vpc              = true
  network_border_group = "us-west-2-wl1-las-wlz-1"
  instance = aws_instance.server.id

  depends_on = [aws_instance.server]

  tags = {
    Name = "SFTP2S3"
  }
}