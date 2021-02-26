## copy the files from the local k8s cluster to the rancher server, to use kubectl
resource "null_resource" "copy_files_k8s" {
  triggers = {
    public_ip = aws_instance.rancher_server.public_ip
  }

  connection {
    type  = "ssh"
    host  = aws_instance.rancher_server.public_ip
    user  = local.node_username
    private_key = tls_private_key.global_key.private_key_pem
  }

  provisioner "file" {
    source      = "./kube_config_workload.yaml"
    destination = "/tmp/rancher/k8s-prod"
  }

  provisioner "file" {
    source      = "./kube_config_workload_dev.yaml"
    destination = "/tmp/rancher/k8s-dev"
  }   

    depends_on = [module.rancher_common.conf_kube_config_workload_yaml,
                  module.rancher_common.conf_kube_config_workload_yaml_dev,
                  aws_instance.rancher_server,
                  module.rancher_common]
}


# wait install all dependences on Rancher server in clusters k8s prod and dev
  resource "time_sleep" "wait_300_seconds" {
  depends_on = [null_resource.copy_files_k8s]

  create_duration = "300s"
}



## Move config cluster kubernets to config kubectl on server rancher
resource "null_resource" "move_config_k8s" {
  triggers = {
    public_ip = aws_instance.rancher_server.public_ip
  }

  connection {
    type  = "ssh"
    host  = aws_instance.rancher_server.public_ip
    user  = local.node_username
    private_key = tls_private_key.global_key.private_key_pem
  }

  // copy kubeconfig to the server
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/rancher/k8s-prod /root/.kube/k8s-prod",
      "sudo mv /tmp/rancher/k8s-dev /root/.kube/k8s-dev"
    ]
  }

  # create service longhorn to storage - prod
  # doc https://longhorn.io/docs/0.8.0/users-guide/create-volumes/
  provisioner "remote-exec" {
    inline = [
      "sudo kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v0.8.0/deploy/longhorn.yaml --kubeconfig=/root/.kube/k8s-prod"
    ]
  } 
  # end longhorn service prod

  # create service longhorn to storage - dev
  provisioner "remote-exec" {
    inline = [
      "sudo kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v0.8.0/deploy/longhorn.yaml --kubeconfig=/root/.kube/k8s-dev"
    ]
  }
  # end longhorn service dev

  # create service traefik-rbac v1.7 to ingress - prod
  # doc https://doc.traefik.io/traefik/

  #first delete namespace nginx-ingress default
  provisioner "remote-exec" {
    inline = [
      "sudo kubectl delete namespace ingress-nginx --kubeconfig=/root/.kube/k8s-prod"
    ]
  }
  #create rbac traefik
  provisioner "remote-exec" {
    inline = [
      "sudo kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-rbac.yaml --kubeconfig=/root/.kube/k8s-prod"
    ]
  }
  # Create ds traefik
   provisioner "remote-exec" {
    inline = [
      "sudo kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-ds.yaml --kubeconfig=/root/.kube/k8s-prod"
    ]
  } 
  ####### end traefik service prod

  # create service traefik-rbac v1.7 to ingress - dev
  # doc https://doc.traefik.io/traefik/

  #first delete namespace nginx-ingress default
  provisioner "remote-exec" {
    inline = [
      "sudo kubectl delete namespace ingress-nginx --kubeconfig=/root/.kube/k8s-dev"
    ]
  }
  #create rbac traefik
  provisioner "remote-exec" {
    inline = [
      "sudo kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-rbac.yaml --kubeconfig=/root/.kube/k8s-dev"
    ]
  }
  # Create ds traefik
   provisioner "remote-exec" {
    inline = [
      "sudo kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-ds.yaml --kubeconfig=/root/.kube/k8s-dev"
    ]
  }
  ####### end traefik service dev
  
    depends_on = [
      null_resource.copy_files_k8s,
      module.rancher_common.conf_kube_config_workload_yaml,
      module.rancher_common.conf_kube_config_workload_yaml_dev,
      aws_spot_instance_request.k8s_cluster_prod,
      aws_spot_instance_request.k8s_cluster_hml,
      time_sleep.wait_300_seconds]
}