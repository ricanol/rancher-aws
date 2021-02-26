# Variables for AWS infrastructure module

// TODO - use null defaults

# Required
variable "aws_access_key" {
  type        = string
  description = "AWS access key used to create infrastructure"
}

variable "instance_count_prod" {
  default = "1"
}

variable "instance_count_hml" {
  default = "1"
}

# Required
variable "aws_secret_key" {
  type        = string
  description = "AWS secret key used to create AWS infrastructure"
}

# Required
variable "mainter" {
  type        = string
  description = "User mainter"
}

# Required
variable "company" {
  type        = string
  description = "Company Name, ATTENTION, ONLY lowercase"
}

variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "Instance type EC2 used for Rancher Server ex: t3.medium"
}

variable "spot_type" {
  type        = string
  description = "Instance type SPOT used for Cluster k8s ex: t3.medium"
}

variable "value_spot" {
  type        = string
  description = "Value instance Spot instance ex: 0.029"
}

variable "domain" {
  type        = string
  description = "Set your domain ex: foo.com"
}

variable "docker_version" {
  type        = string
  description = "Docker version to install on nodes"
  default     = "19.03.15"
}

variable "rke_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for Rancher server RKE cluster"
  default     = "v1.19.4-rancher1-1"
}

variable "workload_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for managed workload cluster"
  default     = "v1.18.15-rancher1-1"
}

variable "cert_manager_version" {
  type        = string
  description = "Version of cert-manager to install alongside Rancher (format: 0.0.0)"
  default     = "1.0.4"
}

variable "rancher_version" {
  type        = string
  description = "Rancher server version (format: v0.0.0)"
  default     = "v2.4.13"
}

# Required
variable "rancher_server_admin_password" {
  type        = string
  description = "Admin password to use for Rancher server bootstrap"
}

# Local variables used to reduce repetition
locals {
  node_username = "ubuntu"
}



#=======================================================
variable "vpcCIDRblockProd" {
    default = "10.0.0.0/16"
}
variable "vpcCIDRblockHml" {
    default = "10.1.0.0/16"
}
variable "instanceTenancy" {
    default = "default"
}
variable "dnsSupport" {
    default = true
}
variable "dnsHostNames" {
    default = true
}
#==========================================
variable "publicsCIDRblockprodA" {
    default = "10.0.10.0/24"
}
variable "privateCIDRblockprodB" {
    default = "10.0.20.0/24"
}
#==========================================
variable "publicsCIDRblockdevC" {
    default = "10.1.10.0/24"
}
variable "privateCIDRblockprodD" {
    default = "10.1.20.0/24"
}
#==========================================
variable "mapPublicIP" {
    default = true
}
variable "mapPrivateIP" {
    default = false
}
