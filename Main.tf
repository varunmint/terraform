terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
          }
  }
}

provider "aws" {
  profile =  "default"
  region = "us-east-1"
}

resource "aws_vpc" "create_vpc" {

    cidr_block = "10.0.0.0/16"
    tags = {
      Environment  = "Production"
    }
      
}

resource "aws_subnet" "create_subnet" {

  vpc_id = aws_vpc.create_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "create subnet"
  }
}  

resource "aws_internet_gateway" "gw" {

  vpc_id = aws_vpc.create_vpc.id
  tags = {
   
    Name = "Internet Gateway"

  }
  
}

resource "aws_route_table" "route_table_igw" {
   vpc_id = aws_vpc.create_vpc.id
route {

  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id

}

route {

  ipv6_cidr_block = "::/0"
  gateway_id = aws_internet_gateway.gw.id
}


tags = {

  Name = " Public route Table "
}
  
}


resource "aws_route_table_association" "public" {

  subnet_id = aws_subnet.create_subnet.id
  route_table_id = aws_route_table.route_table_igw.id
  
}


resource "aws_security_group" "web" {

  name = " HTTP and ssh "
  vpc_id = aws_vpc.create_vpc.id

  ingress  {

    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]    
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]  
}

}

data "aws_ami" "latest_amazon_linux"{
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
}
}

resource "aws_instance" "test1" {

  ami = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  #key_name = "terraform/MyKeyPair.pem"
  subnet_id = aws_subnet.create_subnet.id
  vpc_security_group_ids = [aws_security_group.web.id]
  associate_public_ip_address = true
  user_data = <<-EOF
  #!/bin/bash -ex

  amazon-linux-extras install nginx1 -y
  echo "<h1>$(curl https://api.kanye.rest/?format=text)</h1>" >  /usr/share/nginx/html/index.html 
  systemctl enable nginx
  systemctl start nginx
EOF

  tags = {
    "Name" : "Kanye"
}

}