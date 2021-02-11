# Required variables
# ==========================================================

# AWS Access Key
# aws_access_key = ""

# AWS Secret Key
# aws_secret_key = ""

# Password used to log in to the `admin` account on the new Rancher server
# rancher_server_admin_password = "admin"

# EC2 instance size of all created instances: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html
# instance_type = "t3.medium"

# Spot instance size of all created instances: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html
# spot_type = "t3.medium"

# Spot instance price: https://aws.amazon.com/ec2/spot/pricing/
# value_spot = "0.029"

# Define user mainter
# mainter = "Ricardo"

# Set the domain, otherwise the default will be xip.io
# domain = ""

# Optional variables, uncomment to customize the creation of the environment 
# ----------------------------------------------------------

# AWS region for all resources
# aws_region = "us-east-1"

# Docker version installed on target hosts
# - Must be a version supported by the Rancher install scripts
# docker_version = ""

# Kubernetes version used for creating management server cluster
# - Must be supported by RKE terraform provider 1.0.1
# rke_kubernetes_version = ""

# Kubernetes version used for creating workload cluster
# - Must be supported by RKE terraform provider 1.0.1
# workload_kubernetes_version = ""

# Version of cert-manager to install, used in case of older Rancher versions
# cert_manager_version = ""

# Version of Rancher to install
# rancher_version = ""