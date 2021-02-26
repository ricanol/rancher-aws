# wait 120 seconds for rancher server response
resource "time_sleep" "wait_120_seconds" {
  depends_on = [var.node_public_ip]

  create_duration = "120s"
}

# RKE resources

# Provision RKE cluster on provided infrastructure
resource "rke_cluster" "rancher_cluster" {
  cluster_name = "rancher-cluster"

  nodes {
    address          = var.node_public_ip
    internal_address = var.node_internal_ip
    user             = var.node_username
    role             = ["controlplane", "etcd", "worker"]
    ssh_key          = var.ssh_private_key_pem
  }

#  depends_on = [time_sleep.wait_120_seconds]

  kubernetes_version = var.rke_kubernetes_version
}

