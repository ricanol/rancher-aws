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
  description = "Custom workload cluster created to Rancher Server PROD"

  rke_config {
    network {
      plugin  = var.rke_network_plugin
      options = var.rke_network_options
    }
    kubernetes_version = var.workload_kubernetes_version
  }
  #windows_prefered_cluster = var.windows_prefered_cluster
  enable_cluster_monitoring = true
  cluster_monitoring_input {
    answers = {
      "exporter-kubelets.https" = true
      "exporter-node.enabled" = true
      "exporter-node.ports.metrics.port" = 9796
      "exporter-node.resources.limits.cpu" = "200m"
      "exporter-node.resources.limits.memory" = "200Mi"
      "grafana.persistence.enabled" = false
      "grafana.persistence.size" = "10Gi"
      "grafana.persistence.storageClass" = "default"
      "operator.resources.limits.memory" = "500Mi"
      "prometheus.persistence.enabled" = "false"
      "prometheus.persistence.size" = "50Gi"
      "prometheus.persistence.storageClass" = "default"
      "prometheus.persistent.useReleaseName" = "true"
      "prometheus.resources.core.limits.cpu" = "1000m",
      "prometheus.resources.core.limits.memory" = "1500Mi"
      "prometheus.resources.core.requests.cpu" = "750m"
      "prometheus.resources.core.requests.memory" = "750Mi"
      "prometheus.retention" = "12h"
    }
  }
}
#Create Istio
# Create a new rancher2 Cluster Sync for k8s_workload_prod cluster
resource "rancher2_cluster_sync" "k8s_workload_prod" {
  provider = rancher2.admin

  cluster_id =  rancher2_cluster.k8s_workload_prod.id
  wait_monitoring = rancher2_cluster.k8s_workload_prod.enable_cluster_monitoring
}
# Create a new rancher2 Namespace
resource "rancher2_namespace" "istio-prod" {
  provider = rancher2.admin

  name = "istio-system"
  project_id = rancher2_cluster_sync.k8s_workload_prod.system_project_id
  description = "istio namespace"
}
# Create a new rancher2 App deploying istio (should wait until monitoring is up and running)
resource "rancher2_app" "istio-prod" {
  provider = rancher2.admin

  catalog_name = "system-library"
  name = "cluster-istio"
  description = "Terraform app acceptance test"
  project_id = rancher2_namespace.istio-prod.project_id
  template_name = "rancher-istio"
  #template_version = "0.1.1"
  target_namespace = rancher2_namespace.istio-prod.id
  answers = {
    "certmanager.enabled" = false
    "enableCRDs" = true
    "galley.enabled" = true
    "gateways.enabled" = false
    "gateways.istio-ingressgateway.resources.limits.cpu" = "2000m"
    "gateways.istio-ingressgateway.resources.limits.memory" = "1024Mi"
    "gateways.istio-ingressgateway.resources.requests.cpu" = "100m"
    "gateways.istio-ingressgateway.resources.requests.memory" = "128Mi"
    "gateways.istio-ingressgateway.type" = "NodePort"
    "global.monitoring.type" = "cluster-monitoring"
    "global.rancher.clusterId" = rancher2_cluster_sync.k8s_workload_prod.cluster_id
    "istio_cni.enabled" = "false"
    "istiocoredns.enabled" = "false"
    "kiali.enabled" = "true"
    "mixer.enabled" = "true"
    "mixer.policy.enabled" = "true"
    "mixer.policy.resources.limits.cpu" = "4800m"
    "mixer.policy.resources.limits.memory" = "4096Mi"
    "mixer.policy.resources.requests.cpu" = "1000m"
    "mixer.policy.resources.requests.memory" = "1024Mi"
    "mixer.telemetry.resources.limits.cpu" = "4800m",
    "mixer.telemetry.resources.limits.memory" = "4096Mi"
    "mixer.telemetry.resources.requests.cpu" = "1000m"
    "mixer.telemetry.resources.requests.memory" = "1024Mi"
    "mtls.enabled" = false
    "nodeagent.enabled" = false
    "pilot.enabled" = true
    "pilot.resources.limits.cpu" = "1000m"
    "pilot.resources.limits.memory" = "4096Mi"
    "pilot.resources.requests.cpu" = "500m"
    "pilot.resources.requests.memory" = "2048Mi"
    "pilot.traceSampling" = "1"
    "security.enabled" = true
    "sidecarInjectorWebhook.enabled" = true
    "tracing.enabled" = true
    "tracing.jaeger.resources.limits.cpu" = "500m"
    "tracing.jaeger.resources.limits.memory" = "1024Mi"
    "tracing.jaeger.resources.requests.cpu" = "100m"
    "tracing.jaeger.resources.requests.memory" = "100Mi"
  }
}




# Create custom managed cluster for ${var.prefix}
resource "rancher2_cluster" "k8s_workload_dev" {
  provider = rancher2.admin

  name        = var.workload_cluster_name_dev
  description = "Custom workload cluster created to Rancher Server DEV"

  rke_config {
    network {
      plugin  = var.rke_network_plugin
      options = var.rke_network_options
    }
    kubernetes_version = var.workload_kubernetes_version
  }
  #windows_prefered_cluster = var.windows_prefered_cluster
  enable_cluster_monitoring = true
  cluster_monitoring_input {
    answers = {
      "exporter-kubelets.https" = true
      "exporter-node.enabled" = true
      "exporter-node.ports.metrics.port" = 9796
      "exporter-node.resources.limits.cpu" = "200m"
      "exporter-node.resources.limits.memory" = "200Mi"
      "grafana.persistence.enabled" = false
      "grafana.persistence.size" = "10Gi"
      "grafana.persistence.storageClass" = "default"
      "operator.resources.limits.memory" = "500Mi"
      "prometheus.persistence.enabled" = "false"
      "prometheus.persistence.size" = "50Gi"
      "prometheus.persistence.storageClass" = "default"
      "prometheus.persistent.useReleaseName" = "true"
      "prometheus.resources.core.limits.cpu" = "1000m",
      "prometheus.resources.core.limits.memory" = "1500Mi"
      "prometheus.resources.core.requests.cpu" = "750m"
      "prometheus.resources.core.requests.memory" = "750Mi"
      "prometheus.retention" = "12h"
    }
  }
}
#Create Istio
# Create a new rancher2 Cluster Sync for k8s_workload_dev cluster
resource "rancher2_cluster_sync" "k8s_workload_dev" {
  provider = rancher2.admin

  cluster_id =  rancher2_cluster.k8s_workload_dev.id
  wait_monitoring = rancher2_cluster.k8s_workload_dev.enable_cluster_monitoring
}
# Create a new rancher2 Namespace
resource "rancher2_namespace" "istio-dev" {
  provider = rancher2.admin

  name = "istio-system"
  project_id = rancher2_cluster_sync.k8s_workload_dev.system_project_id
  description = "istio namespace"
}
# Create a new rancher2 App deploying istio (should wait until monitoring is up and running)
resource "rancher2_app" "istio-dev" {
  provider = rancher2.admin
  
  catalog_name = "system-library"
  name = "cluster-istio"
  description = "Terraform app acceptance test"
  project_id = rancher2_namespace.istio-dev.project_id
  template_name = "rancher-istio"
  #template_version = "0.1.1"
  target_namespace = rancher2_namespace.istio-dev.id
  answers = {
    "certmanager.enabled" = false
    "enableCRDs" = true
    "galley.enabled" = true
    "gateways.enabled" = false
    "gateways.istio-ingressgateway.resources.limits.cpu" = "2000m"
    "gateways.istio-ingressgateway.resources.limits.memory" = "1024Mi"
    "gateways.istio-ingressgateway.resources.requests.cpu" = "100m"
    "gateways.istio-ingressgateway.resources.requests.memory" = "128Mi"
    "gateways.istio-ingressgateway.type" = "NodePort"
    "global.monitoring.type" = "cluster-monitoring"
    "global.rancher.clusterId" = rancher2_cluster_sync.k8s_workload_dev.cluster_id
    "istio_cni.enabled" = "false"
    "istiocoredns.enabled" = "false"
    "kiali.enabled" = "true"
    "mixer.enabled" = "true"
    "mixer.policy.enabled" = "true"
    "mixer.policy.resources.limits.cpu" = "4800m"
    "mixer.policy.resources.limits.memory" = "4096Mi"
    "mixer.policy.resources.requests.cpu" = "1000m"
    "mixer.policy.resources.requests.memory" = "1024Mi"
    "mixer.telemetry.resources.limits.cpu" = "4800m",
    "mixer.telemetry.resources.limits.memory" = "4096Mi"
    "mixer.telemetry.resources.requests.cpu" = "1000m"
    "mixer.telemetry.resources.requests.memory" = "1024Mi"
    "mtls.enabled" = false
    "nodeagent.enabled" = false
    "pilot.enabled" = true
    "pilot.resources.limits.cpu" = "1000m"
    "pilot.resources.limits.memory" = "4096Mi"
    "pilot.resources.requests.cpu" = "500m"
    "pilot.resources.requests.memory" = "2048Mi"
    "pilot.traceSampling" = "1"
    "security.enabled" = true
    "sidecarInjectorWebhook.enabled" = true
    "tracing.enabled" = true
    "tracing.jaeger.resources.limits.cpu" = "500m"
    "tracing.jaeger.resources.limits.memory" = "1024Mi"
    "tracing.jaeger.resources.requests.cpu" = "100m"
    "tracing.jaeger.resources.requests.memory" = "100Mi"
  }
}