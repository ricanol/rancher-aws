# Rancher resources

# Initialize Rancher server
resource "rancher2_bootstrap" "admin" {
  depends_on = [
    helm_release.rancher_server
  ]

  provider = rancher2.bootstrap

  password  = var.admin_password
  telemetry = true
}

# Create custom managed cluster for ${var.prefix}
resource "rancher2_cluster" "k8s_workload_prod" {
  provider = rancher2.admin

  name        = var.workload_cluster_name
  description = "Custom workload cluster created to Rancher Server"

  rke_config {
    network {
      plugin  = var.rke_network_plugin
      options = var.rke_network_options
    }
    kubernetes_version = var.workload_kubernetes_version
  }
  #windows_prefered_cluster = var.windows_prefered_cluster
}

# Create custom managed cluster for ${var.prefix}
resource "rancher2_cluster" "k8s_workload_dev" {
  provider = rancher2.admin

  name        = var.workload_cluster_name_dev
  description = "Custom workload cluster created to Rancher Server dev"

  rke_config {
    network {
      plugin  = var.rke_network_plugin
      options = var.rke_network_options
    }
    kubernetes_version = var.workload_kubernetes_version
  }
  #windows_prefered_cluster = var.windows_prefered_cluster
}