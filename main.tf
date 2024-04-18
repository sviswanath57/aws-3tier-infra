### User creation

resource "aws_iam_user" "iam-user" {
  name = "user1"
}

resource "aws_iam_policy" "AWSS3Read-read-only" {
  name        = "AWSS3ReadOnlyAccess"
  description = "AWSS3Read"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Describe*",
                "s3-object-lambda:Get*",
                "s3-object-lambda:List*"
            ],
            "Resource": "*"
        }
    ]
    })
}

resource "aws_iam_policy" "AWSSSM-Instance" {
  name        = "AWSSSMManagedInstanceCore"
  description = "AWSSSMManagedInstanceCore"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:DescribeDocument",
                "ssm:GetManifest",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        }
    ]
    })
}

resource "aws_iam_user_policy_attachment" "awss3read-attach" {
  user       = aws_iam_user.iam-user.name
  policy_arn = aws_iam_policy.AWSS3Read-read-only.arn
}

resource "aws_iam_user_policy_attachment" "awsssm-attach" {
  user       = aws_iam_user.iam-user.name
  policy_arn = aws_iam_policy.AWSSSM-Instance.arn
}

### VPC creation
resource "aws_vpc" "three-tier-vpc" {
 cidr_block = "10.5.0.0/16"
 
 tags = {
   Name = "Project 3 tier VPC"
 }
}

### Public Subnet creation
resource "aws_subnet" "subnet-public-01-1a" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.5.1.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1a"
    tags = {
        Name = "subnet-public-01-1a"
    }
}

resource "aws_subnet" "subnet-public-02-1b" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.5.2.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1b"
    tags = {
        Name = "subnet-public-02-1b"
    }
}

### Private Subnet creation
resource "aws_subnet" "subnet-private-01-1a" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.5.3.0/24"
    #map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1a"
    tags = {
        Name = "subnet-private-01-1a"
    }
}

resource "aws_subnet" "subnet-private-02-1b" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.5.4.0/24"
    #map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1b"
    tags = {
        Name = "subnet-private-02-1b"
    }
}

### Private DB Subnet creation
resource "aws_subnet" "subnet-private-01-db-1a" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.5.5.0/24"
    #map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1a"
    tags = {
        Name = "subnet-private-01-db-1a"
    }
}

resource "aws_subnet" "subnet-private-02-db-1b" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.5.6.0/24"
    #map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1b"
    tags = {
        Name = "subnet-private-02-db-1b"
    }
}

resource "aws_internet_gateway" "tier3_igw" {
vpc_id = aws_vpc.three-tier-vpc.id
tags = {
      Name = "3tier_igw-igw"
    }
}

resource "aws_eip" "eip" {
  domain   = "vpc"
  tags = {
    Name = "aws EIP Public"
  }
}

# NAT Gateway creation
resource "aws_nat_gateway" "nat-3tier-public" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.subnet-public-01-1a.id

  tags = {
    Name = "gateway NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.tier3_igw]
}

# Routing table for public subnet
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.three-tier-vpc.id
  tags = {
    Name        = "${var.environment}-public-route-table"
    Environment = "${var.environment}"
  }
}

# Public routes 
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = var.destination_cidr_block
  gateway_id             = aws_internet_gateway.tier3_igw.id
}

# Public subent assosiation 1a & 2b
resource "aws_route_table_association" "public-assosiation-01a" {
  subnet_id      = aws_subnet.subnet-public-01-1a.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public-assosiation-02b" {
  subnet_id      = aws_subnet.subnet-public-02-1b.id
  route_table_id = aws_route_table.public-route-table.id
}

# App private route table

resource "aws_route_table" "private-route-table-app" {
  vpc_id = aws_vpc.three-tier-vpc.id
  tags = {
    Name        = "${var.environment}-private-route-table-app"
    Environment = "${var.environment}"
  }
}

# db private route table
resource "aws_route_table" "private-route-table-db" {
  vpc_id = aws_vpc.three-tier-vpc.id
  tags = {
    Name        = "${var.environment}-private-route-table-db"
    Environment = "${var.environment}"
  }
}

resource "aws_route" "pri_routes-app" {
  route_table_id = aws_route_table.private-route-table-app.id
  destination_cidr_block = var.destination_cidr_block
  nat_gateway_id = aws_nat_gateway.nat-3tier-public.id
}

resource "aws_route" "pri_routes-db" {
  route_table_id = aws_route_table.private-route-table-db.id
  destination_cidr_block = var.destination_cidr_block
  nat_gateway_id = aws_nat_gateway.nat-3tier-public.id
}

# App Private subent assosiation 1a & 2b
resource "aws_route_table_association" "private-assosiation-01a" {
  subnet_id      = aws_subnet.subnet-private-01-1a.id
  route_table_id = aws_route_table.private-route-table-app.id
}

resource "aws_route_table_association" "private-assosiation-02b" {
  subnet_id      = aws_subnet.subnet-private-02-1b.id
  route_table_id = aws_route_table.private-route-table-app.id
}

# db Private subent assosiation 1a & 2b
resource "aws_route_table_association" "private-assosiation-01a-db" {
  subnet_id      = aws_subnet.subnet-private-01-db-1a.id
  route_table_id = aws_route_table.private-route-table-db.id
}

resource "aws_route_table_association" "private-assosiation-02b-db" {
  subnet_id      = aws_subnet.subnet-private-02-db-1b.id
  route_table_id = aws_route_table.private-route-table-db.id
}


resource "aws_security_group" "public-sg-01" {
  name        = "public-sg-01"
  description = "Public security group for my IP/Laptop"
  vpc_id      = aws_vpc.three-tier-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["103.149.59.241/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["103.149.59.241/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-sg-01"
  }
}

resource "aws_security_group" "public-sg-web-instance-02" {
  name        = "public-sg-web-instance-02"
  description = "Public security group for app instance and my IP/Laptop"
  vpc_id      = aws_vpc.three-tier-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["103.149.59.241/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["103.149.59.241/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.public-sg-01.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-sg-web-instance-01"
  }
}

resource "aws_security_group" "internal-lb-sg-03" {
  name        = "internal-lb-sg-03"
  description = "Public security group for app instance and my IP/Laptop"
  vpc_id      = aws_vpc.three-tier-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["103.149.59.241/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["103.149.59.241/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.public-sg-web-instance-02.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "internal-lb-sg-03"
  }
}

resource "aws_security_group" "private-instances-sg-04" {
  name        = "private-instances-sg-04"
  description = "Public security group for app instance and my IP/Laptop"
  vpc_id      = aws_vpc.three-tier-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["103.149.59.241/32"]
  }

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["103.149.59.241/32"]
  }

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    security_groups = [aws_security_group.internal-lb-sg-03.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-instances-sg-04"
  }
}

resource "aws_security_group" "db-sg-05" {
  name        = "db-sg-05"
  description = "Public security group for app instance and my IP/Laptop"
  vpc_id      = aws_vpc.three-tier-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["103.149.59.241/32"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["103.149.59.241/32"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.private-instances-sg-04.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg-05"
  }
}