### Deploy

To begin with any quickstart, perform the following steps:

1. Clone or download this repository to a local folder
1. Choose a cloud provider and navigate into the provider's folder
1. Copy or rename `terraform.tfvars.example` to `terraform.tfvars` and fill in all required variables
1. Run `terraform init`
1. Run `terraform apply`

When provisioning has finished, terraform will output the URL to connect to the Rancher server.
Two sets of Kubernetes configurations will also be generated:
- `kube_config_server.yaml` contains credentials to access the RKE cluster supporting the Rancher server
- `kube_config_workload.yaml` contains credentials to access the provisioned workload cluster

For more details on each cloud provider, refer to the documentation in their respective folders.

### Remove

When you're finished exploring the Rancher server, use terraform to tear down all resources in the quickstart.

**NOTE: Any resources not provisioned by the quickstart are not guaranteed to be destroyed when tearing down the quickstart.**
Make sure you tear down any resources you provisioned manually before running the destroy command.

Run `terraform destroy -auto-approve` to remove all resources without prompting for confirmation.


# AWS Rancher

Two single-node RKE Kubernetes clusters will be created from two EC2 instances running Ubuntu 18.04 and Docker.
Both instances will have wide-open security groups and will be accessible over SSH using the SSH keys
`id_rsa` and `id_rsa.pub`.

## Variables

###### `aws_access_key`
- **Required**
AWS access key used to create infrastructure

###### `aws_secret_key`
- **Required**
AWS secret key used to create AWS infrastructure

###### `aws_region`
- Default: **`"us-east-1"`**
AWS region used for all resources

###### `prefix`
- Default: **`"rancher"`**
Prefix added to names of all resources

###### `instance_type`
- Default: **`"t3a.medium"`**
Instance type used for all EC2 instances

###### `docker_version`
- Default: **`"19.03"`**
Docker version to install on nodes

###### `rke_kubernetes_version`
- Default: **`"v1.19.4-rancher1-1"`**
Kubernetes version to use for Rancher server RKE cluster

See `rancher-common` module variable `rke_kubernetes_version` for more details.

###### `workload_kubernetes_version`
- Default: **`"v1.18.12-rancher1-1"`**
Kubernetes version to use for managed workload cluster

See `rancher-common` module variable `workload_kubernetes_version` for more details.

###### `cert_manager_version`
- Default: **`"1.0.4"`**
Version of cert-manager to install alongside Rancher (format: 0.0.0)

See `rancher-common` module variable `cert_manager_version` for more details.

###### `rancher_version`
- Default: **`"v2.5.3"`**
Rancher server version (format v0.0.0)

See `rancher-common` module variable `rancher_version` for more details.

###### `rancher_server_admin_password`
- **Required**
Admin password to use for Rancher server bootstrap

See `rancher-common` module variable `admin_password` for more details.
