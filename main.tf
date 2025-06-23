module "tls_private_key" {
  source      = "github.com/deniszm/tf-hashicorp-tls-keys"
  algorithm   = var.tls_algorithm
  ecdsa_curve = var.tls_ecdsa_curve
}

module "github_repository" {
  source                   = "github.com/deniszm/tf-github-repository"
  github_owner             = var.github_owner
  github_token             = var.github_token
  repository_name          = var.flux_github_repo
  public_key_openssh       = module.tls_private_key.public_key_openssh
  public_key_openssh_title = "flux"
}

module "k3d_cluster" {
  source       = "github.com/deniszm/tf-k3d-cluster"
  cluster_name = var.k3d_cluster_name
  agent_count  = var.k3d_agent_count
}

module "flux_bootstrap" {
  source            = "github.com/deniszm/tf-fluxcd-flux-bootstrap"
  github_repository = "${var.github_owner}/${var.flux_github_repo}"
  private_key       = module.tls_private_key.private_key_pem
  config_path       = module.k3d_cluster.kubeconfig_raw
  github_token      = var.github_token
}