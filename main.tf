provider "aws" {
    region = "us-east-2"
    access_key = "<>"
    secret_key = "<>"
}
# Create a VPC
resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "MyVPC"
    }
}
# Create a public subnet
resource "aws_subnet" "pub_sub" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-2a"
    tags = {
        Name = "MyPublicSubnet"
    }
}
# Create a private subnet
resource "aws_subnet" "pvt_sub" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-2a"
    tags = {
        Name = "MyPrivateSubnet"
    }
  
}
# Create an internet gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "MyInternetGateway"
    }
}
# Create a route table
resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "MyRouteTable"
    }
  
}
# Create a route to the internet gateway
resource "aws_route" "internet_access" {
    route_table_id = aws_route_table.rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id    
  
}
# Associate the route table with the public subnet
resource "aws_route_table_association" "pub_sub_association" {
    subnet_id = aws_subnet.pub_sub.id
    route_table_id = aws_route_table.rt.id
}
# Create a security group
resource "aws_security_group" "instance_sg" {
    vpc_id = aws_vpc.main_vpc.id
    name = "instance_sg"

    ingress {
        from_port = 22
        to_port   = 22
        protocol  = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    ingress {
        from_port = 80
        to_port   = 80
        protocol  = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
  
}
# Create an EC2 instance
resource "aws_instance" "web" {
    ami           = "ami-0100e595e1cc1ff7f"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance_sg.name]
    subnet_id = aws_subnet.pub_sub.id
    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y httpd
                systemctl start httpd
                systemctl enable httpd
                echo "<h1>Hello, World!</h1>" > /var/www/html/index.html
                EOF
    tags = {
        Name = "MyWebServer"
    }
}
# elastic IP
resource "aws_eip" "web_eip" {
    instance = aws_instance.web.id
}
# Output the public IP address of the instance
output "instance_ip" {
    value = aws_instance.web.public_ip
}