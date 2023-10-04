provider "aws" {
  region = "eu-west-2"
}

resource "aws_key_pair" "dev_new" {
  key_name   = "dev"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "t2_2xlarge" {
  count         = 3
  ami           = "ami-0eb260c4d5475b901"
  instance_type = "t2.2xlarge"
  key_name      = aws_key_pair.dev_new.key_name
  security_groups = [aws_security_group.allow_ssh_http_https.name]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo DEBIAN_FRONTEND=noninteractive apt-get update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-add-repository ppa:ansible/ansible -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install ansible -y"
    ]
  }
  tags = {
    Name = "t2.2xlarge-instance-${count.index + 1}"
  }
}
resource "aws_security_group" "allow_ssh_http_https" {
  name        = "allow-ssh-http-https"
  description = "Allow SSH, HTTP, and HTTPS traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS from anywhere
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS from anywhere
  }
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow egress traffic to any port
  }
}

resource "aws_eip" "example" {
  count    = 3
  instance = aws_instance.t2_2xlarge[count.index].id
}

output "instance_ips" {
  value = aws_instance.t2_2xlarge[*].public_ip
  description = "Public IP addresses of the created instances"
}

output "elastic_ips" {
  value = aws_eip.example[*].public_ip
  description = "Elastic IP addresses associated with the instances"
}

output "ip_addresses_file" {
  value = join("\n", aws_instance.t2_2xlarge[*].public_ip)
  description = "IP addresses of the created instances in a file format"
}

output "elastic_ip_file" {
  value = join("\n", aws_eip.example[*].public_ip)
  description = "Elastic IP addresses of the instances in a file format"
}

