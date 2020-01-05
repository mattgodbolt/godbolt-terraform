resource "aws_vpc" "minecraft" {
  cidr_block           = "172.32.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "Minecraft"
  }
}

resource "aws_subnet" "minecraft-1a" {
  vpc_id                  = aws_vpc.minecraft.id
  cidr_block              = "172.32.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Minecraft1a"
  }
}

resource "aws_internet_gateway" "minecraft" {
  vpc_id = aws_vpc.minecraft.id
  tags   = {
    Name = "Minecraft"
  }
}

resource "aws_route_table" "minecraft" {
  vpc_id = aws_vpc.minecraft.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.minecraft.id
  }
}

resource "aws_network_acl" "minecraft" {
  vpc_id = aws_vpc.minecraft.id
  egress {
    action     = "allow"
    from_port  = 0
    protocol   = "all"
    rule_no    = 100
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }
  ingress {
    action     = "allow"
    from_port  = 0
    protocol   = "all"
    rule_no    = 100
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_security_group" "minecraft" {
  vpc_id      = aws_vpc.minecraft.id
  name        = "MinecraftSecGroup"
  description = "Security for minecraft"
}

resource "aws_security_group_rule" "mosh" {
  security_group_id = aws_security_group.minecraft.id
  type              = "ingress"
  from_port         = 60000
  to_port           = 61000
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  protocol          = "udp"
  description       = "Allow MOSH from anywhere"
}

resource "aws_security_group_rule" "ssh" {
  security_group_id = aws_security_group.minecraft.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  protocol          = "tcp"
  description       = "Allow SSH from anywhere"
}

resource "aws_security_group_rule" "minecraft-tcp" {
  security_group_id = aws_security_group.minecraft.id
  type              = "ingress"
  from_port         = 25565
  to_port           = 25565
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  protocol          = "tcp"
  description       = "Allow minecraft tcp from anywhere"
}

resource "aws_security_group_rule" "minecraft-udp" {
  security_group_id = aws_security_group.minecraft.id
  type              = "ingress"
  from_port         = 25565
  to_port           = 25565
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  protocol          = "udp"
  description       = "Allow minecraft udp from anywhere"
}

resource "aws_security_group_rule" "EgressToAnywhere" {
  security_group_id = aws_security_group.minecraft.id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  protocol          = "-1"
  description       = "Allow egress to anywhere"
}

data "aws_iam_policy_document" "InstanceAssumeRolePolicy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_instance_profile" "minecraft" {
  name = "MinecraftInstance"
  role = aws_iam_role.minecraft.name
}

resource "aws_iam_role" "minecraft" {
  name               = "MinecraftRole"
  description        = "MinecraftRole node role"
  assume_role_policy = data.aws_iam_policy_document.InstanceAssumeRolePolicy.json
}

data "aws_iam_policy_document" "minecraft-backup" {
  statement {
    sid       = "S3AccessSid"
    actions   = ["s3:*"]
    resources = [
      "${aws_s3_bucket.minecraft.arn}/*",
      aws_s3_bucket.minecraft.arn
    ]
  }
}

resource "aws_iam_policy" "minecraft-backup" {
  name        = "minecraft-backup"
  description = "Can read and write the minecraft s3 backup"
  policy      = data.aws_iam_policy_document.minecraft-backup.json
}

resource "aws_s3_bucket" "minecraft" {
  bucket = "minecraft.godbolt.org"
  acl    = "private"
}

resource "aws_iam_role_policy_attachment" "minecraft_attach_policy" {
  role       = aws_iam_role.minecraft.name
  policy_arn = aws_iam_policy.minecraft-backup.arn
}

resource "aws_instance" "MinecraftNode" {
  ami                         = "ami-04b9e92b5572fa0d1"
  instance_type               = "t3a.medium"
  iam_instance_profile        = aws_iam_instance_profile.minecraft.name
  monitoring                  = false
  key_name                    = "mattgodbolt"
  subnet_id                   = aws_subnet.minecraft-1a.id
  vpc_security_group_ids      = [aws_security_group.minecraft.id]
  associate_public_ip_address = true
  source_dest_check           = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 24
    delete_on_termination = false
  }

  tags = {
    Name = "Minecraft"
  }
}
