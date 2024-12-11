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
  ami           = "ami-0d5eff06f840b45e9"  # Replace with the latest Ubuntu AMI for us-east-1
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.default.id
  security_groups = [
    aws_security_group.allow_all.name
  ]

  tags = {
    Name = "Jenkins Apache Server"
  }

  # User Data script to install Jenkins, Apache, and configure firewall
  user_data = <<-EOF
    #!/bin/bash

    # Define your variables
    DOMAIN="your-domain-name.com"  # Change this to your actual domain
    JENKINS_PORT="8080"           # Default Jenkins port

    # Update and install Java
    sudo apt-get update
    sudo apt-get install -y openjdk-11-jdk

    # Add Jenkins repository and key
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null

    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null

    # Install Jenkins
    sudo apt-get update
    sudo apt-get install -y jenkins
    sudo systemctl start jenkins.service
    sudo systemctl status jenkins

    # Configure firewall
    sudo ufw allow 8080
    sudo ufw enable
    sudo ufw status

    # Get Jenkins initial password
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword

    # Install Apache and enable necessary modules
    sudo apt-get install -y apache2
    sudo a2enmod proxy
    sudo a2enmod proxy_http
    sudo a2enmod headers

    # Navigate to the Apache site configuration directory
    cd /etc/apache2/sites-available/

    # Create a new Jenkins configuration file for Apache
    echo "Creating jenkins.conf for Apache..."
    cat << EOF > jenkins.conf
    <VirtualHost *:80>
        ServerName        $DOMAIN
        ProxyRequests     Off
        ProxyPreserveHost On
        AllowEncodedSlashes NoDecode

        <Proxy http://localhost:$JENKINS_PORT/*>
          Order deny,allow
          Allow from all
        </Proxy>

        ProxyPass         /  http://localhost:$JENKINS_PORT/ nocanon
        ProxyPassReverse  /  http://localhost:$JENKINS_PORT/
        ProxyPassReverse  /  http://$DOMAIN/
    </VirtualHost>

    # Enable the Jenkins site and restart Apache
    echo "Enabling Jenkins site in Apache..."
    sudo a2ensite jenkins

    echo "Restarting Apache service..."
    sudo systemctl restart apache2

    # Restart Jenkins service
    echo "Restarting Jenkins service..."
    sudo systemctl restart jenkins

    # Configure UFW (Uncomplicated Firewall)
    echo "Configuring UFW rules..."
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https

    # Enable UFW
    echo "Enabling UFW..."
    sudo ufw enable

    echo "Setup completed successfully!"
  EOF
}
