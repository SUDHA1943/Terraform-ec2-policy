resource "aws_vpc" "Demo-vpc" {
  cidr_block = "10.0.0.0/16"
}
#subnet
resource "aws_subnet" "Demo-subnet" {
  vpc_id                  = aws_vpc.Demo-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Demo-subnet"
  }
}
#internet gateway
resource "aws_internet_gateway" "Demo-gw" {
  vpc_id = aws_vpc.Demo-vpc.id

  tags = {
    Name = "Demo-gw"
  }
}
#route table
resource "aws_route_table" "Demo-rt" {
  vpc_id = aws_vpc.Demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Demo-gw.id
  }


  tags = {
    Name = "Demo-rt"
  }
}
#route table assocaiatin
resource "aws_route_table_association" "demo-rt-association" {
  subnet_id      = aws_subnet.Demo-subnet.id
  route_table_id = aws_route_table.Demo-rt.id
}
#security group
resource "aws_security_group" "Demo-sg" {
  name        = "Demo-sg"
  description = "Demo-sg"
  vpc_id      = aws_vpc.Demo-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description = "8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Demo-sg"
  }
}
#IAM role creation
resource "aws_iam_role" "terraform" {
  name = "terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
# creating a ec2container full registry policy
resource "aws_iam_policy" "ecrfullregistry" {
  name        = "ecrfullregistry"
  description = "An example policy"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ecr:*",
            "cloudtrail:LookupEvents"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "iam:CreateServiceLinkedRole"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "iam:AWSServiceName" : [
                "replication.ecr.amazonaws.com"
              ]
            }
          }
        }
      ]
  })
}

#attach policy to role
resource "aws_iam_role_policy_attachment" "policyattachrole" {
  policy_arn = aws_iam_policy.ecrfullregistry.arn
  role       = aws_iam_role.terraform.name
}

#ec2 instance
resource "aws_instance" "terraform-jenkins" {
  ami           = "ami-02b49a24cfb95941c"
  instance_type = "t2.micro"
  # vpc_id        = aws_vpc.Demo-vpc.id
  subnet_id            = aws_subnet.Demo-subnet.id
  security_groups      = [aws_security_group.Demo-sg.id]
  user_data            = file("setup-kubernetes.sh")
  iam_instance_profile = aws_iam_instance_profile.profile.name
  tags = {
    Name = "terraform-jenkins"
  }
}

#instance profile
resource "aws_iam_instance_profile" "profile" {
  name = "example-instance-profile"
  role = aws_iam_role.terraform.name
}

