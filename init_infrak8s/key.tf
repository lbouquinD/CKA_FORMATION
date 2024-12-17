resource "aws_key_pair" "k8s" {
    key_name = "k8s"
    public_key = tls_private_key.k8s.public_key_openssh  
}

resource "aws_key_pair" "bastion" {
    key_name = "bastion"
    public_key = tls_private_key.bastion.public_key_openssh  
}

resource "tls_private_key" "k8s" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "tls_private_key" "bastion" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "local_file" "bastion" {
    content = tls_private_key.bastion.private_key_pem
    filename = "/root/.ssh/id_rsa_bastion.pem"
    file_permission = "0400"
}

resource "local_file" "k8s" {
    content = tls_private_key.k8s.private_key_pem
    filename = "/root/.ssh/id_rsa_k8s.pem"
    file_permission = "0400"
}
