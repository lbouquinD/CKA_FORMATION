output "k8s_master_list" {
  value = [
    for i in range(length(aws_instance.k8sMaster)) : {
      name       = aws_instance.k8sMaster[i].tags.Name
      private_ip = aws_instance.k8sMaster[i].private_ip
    }
  ]
}

output "k8s_worker_list" {
  value = [
    for i in range(length(aws_instance.k8sWorker)) : {
      name       = aws_instance.k8sWorker[i].tags.Name
      private_ip = aws_instance.k8sWorker[i].private_ip
    }
  ]
}

output "bastion" {
  description = "Détails sur le bastion"
  value = {
    name       = aws_instance.bastion[0].tags.Name
    private_ip = aws_instance.bastion[0].private_ip
    public_ip  = aws_eip.ip_bastion[0].public_ip
  }
}
