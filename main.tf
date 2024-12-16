provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["C:/Users/JERSON POGI/.aws/credentials"]
  profile                  = "default" # Specify the profile you want to use
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

resource "aws_key_pair" "keypair" {
  key_name   = "my-keypair"                            # Choose a name for the keypair
  public_key = file("C:/Users/JERSON POGI/.ssh/my-keypair.pub") # Path to your public key
}

output "key_pair_name" {
  value = aws_key_pair.keypair.key_name
}

output "key_pair_id" {
  value = aws_key_pair.keypair
}

# Output the public IP of the instance
output "ec2_public_ip" {
  value       = aws_instance.jenkins_apache_server.public_ip
  description = "The public IP address of the EC2 instance"
}

# Fetch your Route 53 Hosted Zone ID for jersonix.online
data "aws_route53_zone" "example" {
  name = "jersonix.online." # Replace with your domain name
}

# Create Route 53 record for 'jenkins.jersonix.online'
resource "aws_route53_record" "jenkins_record" {
  zone_id = data.aws_route53_zone.example.id # Use the hosted zone ID for jersonix.online
  name    = "jenkins.jersonix.online"
  type    = "A"
  ttl     = 300
  records = [aws_instance.jenkins_apache_server.public_ip]
}

# Create CNAME record to forward 'try.jersonix.online' to 'jenkins.jersonix.online'
resource "aws_route53_record" "cname_record" {
  zone_id = data.aws_route53_zone.example.id # Use the hosted zone ID for jersonix.online
  name    = "try.jersonix.online"
  type    = "CNAME"
  ttl     = 300
  records = ["jenkins.jersonix.online"]
}

# Create EC2 Instance with CloudWatch Monitoring
resource "aws_instance" "jenkins_apache_server" {
  ami                         = "ami-0e2c8caa4b6378d8c"
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.default.id
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  associate_public_ip_address = true
  monitoring                  = true  # Enable detailed CloudWatch monitoring

  tags = {
    Name = "Jenkins Apache Server"
  }

  user_data = <<-EOF
  #!/bin/bash
  echo "start"

  # Update package lists
  sudo apt update -y

  # Install OpenJDK and required packages
  sudo apt install -y openjdk-21-jdk openjdk-21-jre

  # Add Jenkins repository key and configure Jenkins repository
  sudo wget -q -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
  echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

  # Install Jenkins
  sudo apt update -y
  sudo apt install -y jenkins
  sudo systemctl start jenkins
  sudo systemctl enable jenkins

  # Configure firewall
  sudo ufw allow from any
  sudo ufw allow to any
  sudo ufw --force enable

  # Install Apache2
  sudo apt install apache2 -y
  sudo a2enmod proxy
  sudo a2enmod proxy_http
  sudo a2enmod headers

  # Create Apache VirtualHost for Jenkins
  sudo bash -c 'cat > /etc/apache2/sites-available/jenkins.conf' <<JENKINS_CONF
  <VirtualHost *:80>
      ServerName jenkins.jersonix.online
      ProxyRequests Off
      ProxyPreserveHost On
      AllowEncodedSlashes NoDecode

       <Proxy http://localhost:8080/*>
         Order deny,allow
         Allow from all
       </Proxy>

       ProxyPass / http://localhost:8080/ nocanon
       ProxyPassReverse / http://localhost:8080/
       ProxyPassReverse / http://jenkins.jersonix.online/
  </VirtualHost>
  JENKINS_CONF

  sudo a2ensite jenkins
  sudo systemctl restart apache2

  # Final success message
  echo "Setup completed successfully!"
  EOF
}

# CloudWatch Log Group for EC2 instance logs
resource "aws_cloudwatch_log_group" "jenkins_log_group" {
  name = "/aws/ec2/jenkins-apache-logs"
  retention_in_days = 7  # Retain logs for 7 days
}

# CloudWatch Log Stream for the instance logs
resource "aws_cloudwatch_log_stream" "jenkins_log_stream" {
  log_group_name = aws_cloudwatch_log_group.jenkins_log_group.name
  name           = "jenkins-apache-stream"
}

# CloudWatch Alarm for CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "High-CPU-Utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarm when CPU utilization is above 80%"
  dimensions = {
    InstanceId = aws_instance.jenkins_apache_server.id
  }

  # Send notification to an SNS topic (optional)
  alarm_actions = []
}
