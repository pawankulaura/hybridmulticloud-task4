Succesfully Completed #Task-4 with additional nat gateway in task3
#Task-3+4
#1 Write a Infrastructure as code using terraform, which automatically create a VPC.
#2 In that VPC we have to create 2 subnets:
##a  public  subnet [ Accessible for Public World! ] 
##b  private subnet [ Restricted for Public World! ]
#3 Create a public facing internet gateway for connect our VPC/Network to the internet world and attach this gateway to our VPC.
#4 Create  a routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.
#5 Launch an ec2 instance which has Wordpress setup already having the security group allowing  port 80 so that our client can connect to our wordpress site.
##Also attach the key to instance for further login into it.
#6 Launch an ec2 instance which has MYSQL setup already with security group allowing  port 3306 in private subnet so that our wordpress vm can connect with the same.
##Also attach the key with the same.
###Note: Wordpress instance has to be part of public subnet so that our client can connect our site. 
####mysql instance has to be part of private  subnet so that outside world can't connect to it.
####Don't forgot to add auto ip assign and auto dns name assignment option to be enabled.

provider "aws" {
  region = "ap-south-1"
  profile = "pawan"
}
//creating the vpc
resource "aws_vpc" "vpc1" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "vpc1"
  }
}

//creating subnet1
resource "aws_subnet" "subnet1" {
  vpc_id = "${aws_vpc.vpc1.id}"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  cidr_block = "192.168.0.0/24"
  tags = {
    Name = "subnet-1"
  }
}

//Creating subnet2
resource "aws_subnet" "subnet2" {
  vpc_id = "${aws_vpc.vpc1.id}"
  availability_zone = "ap-south-1a"
  cidr_block = "192.168.1.0/24"
  tags = {
    Name = "subnet-2"
  }
}

//Creating the Internet Gateway (Router) and attaching it vpc1.
resource "aws_internet_gateway" "router1" {
  vpc_id = "${aws_vpc.vpc1.id}"
  tags = {
    Name = "router-1"
  }
}

//Creating Routing Table for the Internet Gateway.
resource "aws_route_table" "rtable1" {
  vpc_id = "${aws_vpc.vpc1.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.router1.id}"
  }
  tags = {
    Name = "rtable-1"
  }
}

//Creating the subnet association for the subnet-1 to access the outside world of internet.
resource "aws_route_table_association" "tableattach" {
  subnet_id = "${aws_subnet.subnet1.id}"
  route_table_id = "${aws_route_table.rtable1.id}"
}


//Creating Security-Group for Word-Press. 
resource "aws_security_group" "SG1" {
  name        = "Word-Press-SG"
  description = "Allow SSH,HTTP"
  vpc_id      = "${aws_vpc.vpc1.id}"


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "sg1"
  }
}

//Creating Security-Group for MySQL allowing port 3306.description
resource "aws_security_group" "SG2" {
  name        = "MySQL-SG"
  description = "Allow port 3306"
  vpc_id      = "${aws_vpc.vpc1.id}"


  ingress {
    description = "MySQL-port"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "sg2"
  }
}


//Launching an Instance which has WordPress already setup. 
resource aws_instance "wordpressnode" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  key_name      = "pawan"
  security_groups = [ "${aws_security_group.SG1.id}"]
  subnet_id = "${aws_subnet.subnet1.id}"
  


  tags = {
    Name = "WordPress-node"
  }
}

//Launching an Instance which has mysql already setup. 

resource aws_instance "mysqlnode" {
  ami           = "ami-0019ac6129392a0f2"
  instance_type = "t2.micro"
  key_name      = "pawan"
  security_groups = [ "${aws_security_group.SG2.id}"]
  subnet_id = "${aws_subnet.subnet2.id}"
  


  tags = {
    Name = "MySQL-node"
  }
}


