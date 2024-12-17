variable "availability_zones" {
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}
resource "aws_instance" "bastion" {
  count = 1
  ami           = "ami-04dd23e62ed049936"
  instance_type = "t2.small"
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  subnet_id = aws_subnet.public_subnet.id
  key_name =  "bastion"
  depends_on = [aws_key_pair.bastion]
  availability_zone = var.availability_zones[0]
  user_data = <<EOF
#!/bin/bash
echo "Copying the SSH Key to the server"
echo -e "${tls_private_key.k8s.private_key_pem}" >> /home/ubuntu/.ssh/id_rsa_k8s.pem
chmod 400 /home/ubuntu/.ssh/id_rsa_k8s.pem
EOF
  tags = {
    Name = "Bastion"
  }
}

resource "aws_instance" "k8sMaster" {
  count = 3
  ami           = "ami-04dd23e62ed049936"
  instance_type = "t2.small"
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  subnet_id = aws_subnet.private_subnet.id
  depends_on = [aws_key_pair.k8s]
  key_name = "k8s"
  availability_zone = var.availability_zones[0]
  tags = {
    Name = "k8smaster${count.index}"
  }
}

resource "aws_instance" "k8sWorker" {
  count = 3
  ami           = "ami-04dd23e62ed049936"
  instance_type = "t2.small"
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  subnet_id = aws_subnet.private_subnet.id
  depends_on = [aws_key_pair.k8s]
  key_name = "k8s" 
  availability_zone = var.availability_zones[0]
  tags = {
    Name = "k8sworker${count.index}"
  }
}
