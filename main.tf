provider "aws" {
  region                     = "us-east-1"
  shared_credentials_files    = ["/Users/JERSON POGI/.aws/credentials"]
}

# Fetch default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch default subnet in the default VPC
data "aws_subnet" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create security group to allow all inbound and outbound traffic
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound and outbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 instance for Jenkins and Apache server
resource "aws_instance" "jenkins_apache_server" {
  ami           = "ami-0e2c8caa4b6378d8c"  # Replace with the latest Ubuntu AMI for us-east-1
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.default.id  # Ensure this subnet is correct
  vpc_security_group_ids = [aws_security_group.allow_all.id]  # Use vpc_security_group_ids instead of security_groups

  associate_public_ip_address = true  # Enable public IP address for the EC2 instance

  tags = {
    Name = "Jenkins Apache Server"
  }

  # User Data script to install Jenkins, Apache, and configure firewall
  user_data = <<-EOF
   sleep 200
   
    #!/bin/bash

# Update package list
sudo apt update
sleep 60

# Install OpenJDK 21 JDK
sudo apt install openjdk-21-jdk -y
sleep 60

# Install OpenJDK 21 JRE
sudo apt install openjdk-21-jre -y
sleep 60

# Add Jenkins repository and key
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
sleep 60

# Configure Jenkins repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sleep 60

# Update package list again
sudo apt-get update
sleep 60

# Install Jenkins
sudo apt-get install jenkins -y

# Start Jenkins service
sudo systemctl start jenkins.service

# Check Jenkins service status
sudo systemctl status jenkins

# Allow traffic on port 8080 (Jenkins)
sudo ufw allow 8080

# Enable UFW
sudo ufw enable

# Check UFW status
sudo ufw status

  EOF
}
