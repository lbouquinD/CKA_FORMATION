resource "local_file" "hosts_ini" {
  content  =  templatefile("inventory_k8s_template.tfpl", { masters = aws_instance.k8sMaster[*], workers = aws_instance.k8sWorker[*],bastion=aws_instance.bastion[0],ipbastion = aws_eip.ip_bastion[0]} )
  filename = "${path.module}/host.ini"
  depends_on = [aws_instance.k8sMaster, aws_instance.k8sWorker]
}

resource "local_file" "ssh-config" {
  content  =  templatefile("ssh_config_template.tfpl", { eip = aws_eip.ip_bastion[0].public_ip} )
  filename = "/root/.ssh/config"
  depends_on = [aws_eip.ip_bastion]
}


resource "local_file" "hosts" {
  content  =  templatefile("hosts_template.tfpl", { masters = aws_instance.k8sMaster[*], workers = aws_instance.k8sWorker[*], bastionIP = aws_eip.ip_bastion[0]} )
  filename = "${path.module}/hosts"
  depends_on = [aws_instance.k8sMaster, aws_instance.k8sWorker]
}


resource "null_resource" "update_hosts" {
  triggers = {
    content_hash = filemd5("${path.module}/hosts")
  }
  depends_on = [local_file.hosts]
  provisioner "local-exec" {
    command = <<EOT
    # Supprimer les balises # BEGIN TERRAFORM, # END TERRAFORM et tout ce qui est entre elles
    sed -i '/# BEGIN TERRAFORM/,/# END TERRAFORM/{//!d}' /etc/hosts #supression de ce qu'il y a entre ces balises 
    sed -i '/# BEGIN TERRAFORM/,/# END TERRAFORM/d'  /etc/hosts #supression des balises 
    cat ${path.module}/hosts >> /etc/hosts 
    EOT
  }

}



resource "null_resource" "set_hosts" {
  depends_on = [null_resource.update_hosts]
  connection {
    type  = "ssh"
    host  = aws_eip.ip_bastion[0].public_ip
    user  = "ubuntu"
    private_key = tls_private_key.bastion.private_key_pem
 }
 triggers = {
    always_run = "${timestamp()}"
 }
 provisioner "file" {
    source  = "hosts"  # local public key
    destination  = "/tmp/hosts"  # will copy to remote VM as /tmp/test.pub
  }
 provisioner "remote-exec" {
    inline = [
    "# Supprimer les balises # BEGIN TERRAFORM, # END TERRAFORM et tout ce qui est entre elles",
    "sudo sed -i '/# BEGIN TERRAFORM/,/# END TERRAFORM/{//!d}' /etc/hosts #supression de ce qu'il y a entre ces balises ",
    "sudo sed -i '/# BEGIN TERRAFORM/,/# END TERRAFORM/d'  /etc/hosts #supression des balises ",
    "sudo tee -a /etc/hosts < /tmp/hosts",
    ]
  }
}
