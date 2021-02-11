# Outputs

output "rancher_url" {
  value = "https://${var.rancher_server_dns}"
}

output "custom_cluster_command" {
  value       = rancher2_cluster.k8s_workload_prod.cluster_registration_token.0.node_command
  description = "Docker command used to add a node to the k8s cluster PROD"
}

output "custom_cluster_command_dev" {
  value       = rancher2_cluster.k8s_workload_dev.cluster_registration_token.0.node_command
  description = "Docker command used to add a node to the k8s cluster DEV"
}

#output "custom_cluster_windows_command" {
#  value       = rancher2_cluster.k8s_workload_dev.cluster_registration_token.0.windows_node_command
#  description = "Docker command used to add a windows node to the k8s cluster"
#}

output "conf_kube_server" {
  value = local_file.kube_config_server_yaml
}

output "conf_kube_prod" {
  value = local_file.kube_config_workload_yaml
}

output "conf_kube_dev" {
  value = local_file.kube_config_workload_yaml_dev
}

output "cluster_done_prod" {
  value = rancher2_cluster.k8s_workload_prod
}

output "cluster_done_dev" {
  value = rancher2_cluster.k8s_workload_dev
}