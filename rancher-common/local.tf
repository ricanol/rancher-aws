# Local resources

# Save kubeconfig file for interacting with the RKE cluster on your local machine
resource "local_file" "kube_config_server_yaml" {
  filename = format("%s/%s", path.root, "kube_config_server.yaml")
  content  = rke_cluster.rancher_cluster.kube_config_yaml
}

resource "local_file" "kube_config_workload_yaml" {
  filename = format("%s/%s", path.root, "kube_config_workload.yaml")
  content  = rancher2_cluster.k8s_workload_prod.kube_config
}

resource "local_file" "kube_config_workload_yaml_dev" {
  filename = format("%s/%s", path.root, "kube_config_workload_dev.yaml")
  content  = rancher2_cluster.k8s_workload_dev.kube_config
}

