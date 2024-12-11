provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["/Users/JERSON POGI/.aws/credentials"]
}

resource "aws_instance" "jenkins_apache_server" {
  ami           = "ami-0d5eff06f840b45e9" # Replace with the latest Ubuntu AMI for us-east-1
  instance_type = "t2.micro"
  subnet_id     = "${data.aws_subnet.default.id}"

  security_groups = [
    aws_security_group.allow_all.name
  ]

  tags = {
    Name = "Jenkins Apache Server"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y openjdk-11-jdk

    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null

    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y jenkins
    sudo systemctl start jenkins.service
    sudo systemctl status jenkins
    sudo ufw allow 8080
    sudo ufw enable
    sudo ufw status
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword

    sudo apt-get install -y apache2
    sudo a2enmod proxy
    sudo a2enmod proxy_http
    sudo a2enmod headers

    cat << APACHE_CONF | sudo tee /etc/apache2/sites-available/jenkins.conf
    <VirtualHost *:80>
        ServerName jenkins.example.com

        ProxyRequests Off
        ProxyPreserveHost On
        AllowEncodedSlashes NoDecode

        <Proxy *>
            Require all granted
        </Proxy>

        ProxyPass         /  http://localhost:8080/ nocanon
        ProxyPassReverse  /  http://localhost:8080/

        ErrorLog ${APACHE_LOG_DIR}/jenkins_error.log
        CustomLog ${APACHE_LOG_DIR}/jenkins_access.log combined

    </VirtualHost>
    APACHE_CONF

    sudo a2ensite jenkins.conf
    sudo systemctl restart apache2
  EOF
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

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
