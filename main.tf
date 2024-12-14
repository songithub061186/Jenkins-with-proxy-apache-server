provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["C:/Users/PC/.aws/credentials"]
  profile                  = "default"  # Specify the profile you want to use
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
  key_name   = "my-keypair"  # Choose a name for the keypair
  public_key = file("C:/Users/PC/.ssh/my-keypair.pub")  # Path to your public key

}


output "key_pair_name" {
  value = aws_key_pair.keypair.key_name
}

output "key_pair_id" {
  value = aws_key_pair.keypair
}

# Output the public IP of the instance
output "ec2_public_ip" {
  value = aws_instance.jenkins_apache_server.public_ip
  description = "The public IP address of the EC2 instance"
}


# Fetch your Route 53 Hosted Zone ID for jersonix.online
data "aws_route53_zone" "example" {
  name = "jersonix.online."  # Replace with your domain name
}

# Create Route 53 record for 'jenkins.jersonix.online'
resource "aws_route53_record" "jenkins_record" {
  zone_id = data.aws_route53_zone.example.id  # Use the hosted zone ID for jersonix.online
  name    = "jenkins.jersonix.online"
  type    = "A"
  ttl     = 300
  records = [aws_instance.jenkins_apache_server.public_ip]
}

# Create CNAME record to forward 'try.jersonix.online' to 'jenkins.jersonix.online'
resource "aws_route53_record" "cname_record" {
  zone_id = data.aws_route53_zone.example.id  # Use the hosted zone ID for jersonix.online
  name    = "try.jersonix.online"
  type    = "CNAME"
  ttl     = 300
  records = ["jenkins.jersonix.online"]
}

# Create EC2 instance for Jenkins and Apache server
resource "aws_instance" "jenkins_apache_server" {
  ami                    = "ami-0e2c8caa4b6378d8c" # Replace with the latest Ubuntu AMI for us-east-1
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.default.id        # Ensure this subnet is correct
  vpc_security_group_ids = [aws_security_group.allow_all.id] # Use vpc_security_group_ids instead of security_groups

  associate_public_ip_address = true # Enable public IP address for the EC2 instance

  tags = {
    Name = "Jenkins Apache Server"
  }

  # User Data script to install Jenkins, Apache, and configure firewall
  user_data = <<-EOF
    user_data = <<-EOF
    #!/bin/bash
    echo "start"  # Log the start of the script
    
    # Update package lists
    echo "Updating package lists..."
    sudo apt update -y

    # Install OpenJDK and required packages
    echo "Installing OpenJDK 21..."
    sudo apt install -y openjdk-21-jdk openjdk-21-jre

    # Add Jenkins repository key
    echo "Adding Jenkins repository key..."
    sudo wget -q -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

    # Configure Jenkins repository
    echo "Configuring Jenkins repository..."
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

    # Update package lists after adding Jenkins repository
    echo "Updating package lists after adding Jenkins repository..."
    sudo apt update -y

    # Install Jenkins
    echo "Installing Jenkins..."
    sudo apt install -y jenkins

    # Start and enable Jenkins service
    echo "Starting and enabling Jenkins service..."
    sudo systemctl start jenkins
    sudo systemctl enable jenkins

    # Allow traffic on port 8080 (Jenkins)
    echo "Configuring firewall for Jenkins..."
    sudo ufw allow 8080

    # Enable UFW without confirmation prompt
    sudo ufw --force enable

    # Display Jenkins service status
    echo "Displaying Jenkins service status..."
    sudo systemctl status jenkins

    # Install Apache2 and enable required modules
    echo "Installing and configuring Apache2..."
    sudo apt install apache2 -y
    sudo a2enmod proxy
    sudo a2enmod proxy_http
    sudo a2enmod headers

    # Create the Apache Virtual Host configuration for Jenkins
    echo "Creating Apache VirtualHost for Jenkins..."
    JENKINS_CONF_PATH="/etc/apache2/sites-available/jenkins.conf"
    sudo bash -c "cat > $JENKINS_CONF_PATH" <<JENKINS_CONF
<VirtualHost *:80>
    ServerName jenkins.jersonix.online
    ServerAlias try.jersonix.online
    ProxyRequests Off
    ProxyPreserveHost On
    AllowEncodedSlashes NoDecode

    <Proxy http://localhost:8080/*>
        Require all granted
    </Proxy>

    ProxyPass / http://localhost:8080/ nocanon
    ProxyPassReverse / http://localhost:8080/
    ProxyPassReverse / http://jenkins.jersonix.online/
    ProxyPassReverse / http://try.jersonix.online/
</VirtualHost>
JENKINS_CONF

    # Enable the new Jenkins site in Apache
    echo "Enabling Jenkins site in Apache..."
    sudo a2ensite jenkins

    # Restart Apache to apply changes
    echo "Restarting Apache..."
    sudo systemctl restart apache2

    # Allow necessary firewall rules
    echo "Configuring firewall for web access..."
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https

    # Final success message
    echo "Setup completed successfully! Visit http://jenkins.jersonix.online to access Jenkins."
  EOF
}
