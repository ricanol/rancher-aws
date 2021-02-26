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

# Security group to allow all traffic VPC prod
resource "aws_security_group" "rancher_sg_allowall" {
  name        = "rancher-server-prod-public-sg"
  vpc_id      = aws_vpc.vpc_prod.id
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
    Name = "rancher-server-prod-public-sg"
  }
}

# AWS EC2 instance for creating a single node RKE cluster and installing the Rancher server
resource "aws_instance" "rancher_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.Public_subnet_prod_A.id

  key_name        = aws_key_pair.generate_key_pair.key_name
  security_groups = [aws_security_group.rancher_sg_allowall.id]

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
  depends_on = [aws_subnet.Public_subnet_prod_A]
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

  node_username          = local.node_username
  ssh_private_key_pem    = tls_private_key.global_key.private_key_pem
  rke_kubernetes_version = var.rke_kubernetes_version

    cert_manager_version = var.cert_manager_version
    rancher_version      = var.rancher_version

  rancher_server_dns = join(".", ["rancher", var.domain])

  admin_password = var.rancher_server_admin_password

  workload_kubernetes_version = var.workload_kubernetes_version
  workload_cluster_name            = "k8s-${var.company}-prod"
  workload_cluster_name_dev        = "k8s-${var.company}-dev"
  
}

# AWS EC2 instance for creating a single node workload cluster PROD
resource "aws_spot_instance_request" "k8s_cluster_prod" {
  count         = var.instance_count_prod
  subnet_id     = aws_subnet.Private_subnet_prod_B.id

  ami           = data.aws_ami.ubuntu.id
  wait_for_fulfillment = true
  spot_price    = var.value_spot
  instance_type = var.spot_type

  key_name        = aws_key_pair.generate_key_pair.key_name
  security_groups = [aws_security_group.rancher_sg_allowall.id]

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

  tags = {
    Name    = "k8s_cluster_prod_${count.index + 1}"
    Creator = "rancher-server"
  }
  depends_on = [aws_subnet.Private_subnet_prod_B]
}

## Create DNS internal to cluster k8s prod
resource "aws_route53_record" "dns_k8s_prod" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name = join(".", ["*","prod","rancher", var.domain])
  type = "A"
  ttl = "300"
  records = [aws_spot_instance_request.k8s_cluster_prod[0].public_ip]

  depends_on = [aws_spot_instance_request.k8s_cluster_prod]
}


# AWS EC2 instance for creating a single node workload cluster HML
resource "aws_spot_instance_request" "k8s_cluster_hml" {
  count         = var.instance_count_hml
  subnet_id     = aws_subnet.Private_subnet_hml_D.id

  ami           = data.aws_ami.ubuntu.id
  wait_for_fulfillment = true
  spot_price    = var.value_spot
  instance_type = var.spot_type

  key_name        = aws_key_pair.generate_key_pair.key_name
  security_groups = [aws_security_group.rancher_sg_allowall.id]

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

  tags = {
    Name    = "k8s_cluster_hml_${var.company}"
  }
  depends_on = [aws_subnet.Private_subnet_hml_D]
}

## Create DNS internal to cluster k8s prod
resource "aws_route53_record" "dns_k8s_hml" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name = join(".", ["*","hml","rancher", var.domain])
  type = "A"
  ttl = "300"
  records = [aws_spot_instance_request.k8s_cluster_hml[0].public_ip]

  depends_on = [aws_spot_instance_request.k8s_cluster_hml]
}