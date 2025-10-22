resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true


  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# Availability Zones
data "aws_availability_zones" "available" {}

# Public Subnets
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet-az1"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# Associate Public Subnet
resource "aws_route_table_association" "public_az1_assoc" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Subnets
resource "aws_subnet" "private_subnet_az1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private-subnet-az1"
  }
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}

# Associate Private Subnet
resource "aws_route_table_association" "private_az1_assoc" {
  subnet_id      = aws_subnet.private_subnet_az1.id
  route_table_id = aws_route_table.private_rt.id
}

# VPC Endpoint for S3
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type  = "Gateway"
  route_table_ids    = [aws_route_table.private_rt.id]

  tags = {
    Name = "s3-vpc-endpoint"
  }
}

# IAM Role + Instance Profile for EC2

resource "aws_iam_role" "ec2_s3_role" {
  name = "${var.project_name}-${var.environment}-ec2-s3-role"


  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-s3-profile"

  role = aws_iam_role.ec2_s3_role.name
}

resource "aws_security_group" "bastion_sg" {
  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Enable HTTP (80) and SSH (22) access"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-sg"
  }
}



# Security Group for Private EC2
resource "aws_security_group" "private_ec2_sg" {
  name        = "${var.project_name}-${var.environment}-private-sg"
  description = "Enable SSH access"
  vpc_id      = aws_vpc.vpc.id

  ingress {
  description     = "SSH from Bastion only"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  security_groups = [aws_security_group.bastion_sg.id]
}


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-sg"
  }
}


# Get Key Pair
data "aws_key_pair" "key_pair" {
  key_name = var.key_pair
}

# bastion Server
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_pair
  subnet_id                   = aws_subnet.public_subnet_az1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion"
  }
}


# private ec2 server
resource "aws_instance" "private_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_pair
  subnet_id                   = aws_subnet.private_subnet_az1.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.private_ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  user_data = file("../scripts/s3-test.sh")

  tags = {
    Name = "${var.project_name}-${var.environment}-private-ec2"
  }
}
