# AWS infrastructure resources

resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "ssh_private_key_pem" {
  filename          = "${path.module}/id_rsa"
  sensitive_content = tls_private_key.global_key.private_key_pem
  file_permission   = "0600"
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.module}/id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

# Temporary key pair used for SSH accesss
resource "aws_key_pair" "generate_key_pair" {
  key_name_prefix = "rancher-server-key"
  public_key      = tls_private_key.global_key.public_key_openssh
}

# Security group to allow all traffic
resource "aws_security_group" "rancher_sg_allowall" {
  name        = "rancher-server-allowall-sg"
  description = "Rancher Server - allow all traffic"

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Creator = "rancher-server"
  }
}

# AWS EC2 instance for creating a single node RKE cluster and installing the Rancher server
resource "aws_instance" "rancher_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  key_name        = aws_key_pair.generate_key_pair.key_name
  security_groups = [aws_security_group.rancher_sg_allowall.name]

  user_data = templatefile(
    join("/", [path.module, "../cloud-common/files/userdata_rancher_server.template"]),
    {
      docker_version = var.docker_version
      username       = local.node_username
    }
  )

  root_block_device {
    volume_size = 80
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
      "sudo mkdir -p /root/.kube"
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  #Install kubctl rancher-server
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2",
      "sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "sudo echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee -a /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y kubectl",
      "sudo mkdir -p /tmp/S3/files/",
      "sudo mkdir /tmp/app/",
      "sudo mkdir /tmp/rancher/",
      "sudo chmod -R 777 /tmp/"
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  tags = {
    Name    = "rancher-server"
    Creator = "rancher-${var.mainter}"
  }
}

data "aws_route53_zone" "selected" {
  name         = var.domain
  private_zone = false
}

## Create DNS internal to Rancher-server
resource "aws_route53_record" "dns_rancher_server" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name = join(".", ["rancher", var.domain])
  type = "A"
  ttl = "300"
  records = [aws_instance.rancher_server.public_ip]

  depends_on = [aws_instance.rancher_server]
}

# Rancher resources
module "rancher_common" {
  source = "../rancher-common"

  node_public_ip         = aws_instance.rancher_server.public_ip
  node_internal_ip       = aws_instance.rancher_server.private_ip

  #node_public_ip_dev     = aws_instance.rancher_server.public_ip
  #node_internal_ip_dev   = aws_instance.rancher_server.private_ip
  
  node_username          = local.node_username
  ssh_private_key_pem    = tls_private_key.global_key.private_key_pem
  rke_kubernetes_version = var.rke_kubernetes_version

    cert_manager_version = var.cert_manager_version
    rancher_version      = var.rancher_version

  rancher_server_dns = join(".", ["rancher", var.domain])

  admin_password = var.rancher_server_admin_password

  workload_kubernetes_version = var.workload_kubernetes_version
  workload_cluster_name            = "cluster-k8s-natura-prod"
  workload_cluster_name_dev        = "cluster-k8s-natura-dev"
  
}

# AWS EC2 instance for creating a single node workload cluster PROD
resource "aws_spot_instance_request" "k8s_cluster_prod" {
  ami           = data.aws_ami.ubuntu.id
  wait_for_fulfillment = true
  spot_price    = var.value_spot
  instance_type = var.spot_type

  key_name        = aws_key_pair.generate_key_pair.key_name
  security_groups = [aws_security_group.rancher_sg_allowall.name]

  user_data = templatefile(
    join("/", [path.module, "files/userdata_node.template"]),
    {
      docker_version   = var.docker_version
      username         = local.node_username
      register_command = module.rancher_common.custom_cluster_command
    }
  )

  root_block_device {
    volume_size = 80
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
      "sudo mkdir /tmp/app/",
      "sudo chmod -R 777 /tmp/"
    ]

    connection {
      type        = "ssh"
      host        = aws_spot_instance_request.k8s_cluster_prod.public_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  tags = {
    Name    = "k8s_cluster_prod"
    Creator = "rancher-server"
  }
}


## Create wild-card to cluster prod
resource "aws_route53_record" "dns_wild_card_prod" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name = join(".", ["*", "prod" , "rancher", var.domain])
  type = "CNAME"
  ttl = "300"
  records = [aws_spot_instance_request.k8s_cluster_prod.public_ip,
            ]
}

# AWS EC2 instance for creating a single node workload cluster DEV
resource "aws_spot_instance_request" "k8s_cluster_dev" {
  ami           = data.aws_ami.ubuntu.id
  wait_for_fulfillment = true
  spot_price    = var.value_spot
  instance_type = var.spot_type

  key_name        = aws_key_pair.generate_key_pair.key_name
  security_groups = [aws_security_group.rancher_sg_allowall.name]

  user_data = templatefile(
    join("/", [path.module, "files/userdata_node.template"]),
    {
      docker_version   = var.docker_version
      username         = local.node_username
      register_command = module.rancher_common.custom_cluster_command_dev
    }
  )

  root_block_device {
    volume_size = 80
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
      "sudo mkdir /tmp/app/",
      "sudo chmod -R 777 /tmp/",
    ]

    connection {
      type        = "ssh"
      host        = aws_spot_instance_request.k8s_cluster_dev.public_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  tags = {
    Name    = "k8s_cluster_dev"
    Creator = "rancher-server"
  }
}

## Create wild-card to cluster dev
resource "aws_route53_record" "dns_wild_card_dev" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name = join(".", ["*", "dev" , "rancher", var.domain])
  type = "CNAME"
  ttl = "300"
  records = [aws_spot_instance_request.k8s_cluster_dev.public_ip,
            ]

depends_on = [aws_spot_instance_request.k8s_cluster_dev,
              var.domain
              ]
}