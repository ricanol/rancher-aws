output "rancher_server_url" {
  value = module.rancher_common.rancher_url
}

output "rancher_node_ip" {
  value = aws_instance.rancher_server.public_ip
}

output "workload_node_ip_prod" {
  value = aws_spot_instance_request.k8s_cluster_prod.public_ip
}

output "workload_node_ip_dev" {
  value = aws_spot_instance_request.k8s_cluster_dev.public_ip
}