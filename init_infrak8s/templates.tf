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
  content  =  templatefile("hosts_template.tfpl", { masters = aws_instance.k8sMaster[*], workers = aws_instance.k8sWorker[*]} )
  filename = "${path.module}/hosts"
  depends_on = [aws_instance.k8sMaster, aws_instance.k8sWorker]
}
