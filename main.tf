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
  config_path       = var.config_path
  github_token      = var.github_token
}

# Create GitRepository manifest for obot in flux-gitops repo
resource "github_repository_file" "obot_gitrepository" {
  depends_on = [module.flux_bootstrap]

  repository = var.flux_github_repo
  branch     = "main"
  file       = "clusters/local/obot-gitrepository.yaml"
  content = <<-EOT
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: obot
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/deniszm/obot
  ref:
    branch: main
EOT
  commit_message      = "Add obot GitRepository"
  commit_author       = var.github_owner
  commit_email        = "${var.github_owner}@users.noreply.github.com"
  overwrite_on_create = true
}

# Create HelmRelease manifest for obot in flux-gitops repo
resource "github_repository_file" "obot_helmrelease" {
  depends_on = [github_repository_file.obot_gitrepository]

  repository = var.flux_github_repo
  branch     = "main"
  file       = "clusters/local/obot-helmrelease.yaml"
  content = <<-EOT
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: obot
  namespace: default
spec:
  interval: 5m
  chart:
    spec:
      chart: helm
      version: "*"
      sourceRef:
        kind: GitRepository
        name: obot
        namespace: flux-system
EOT
  commit_message      = "Add obot HelmRelease"
  commit_author       = var.github_owner
  commit_email        = "${var.github_owner}@users.noreply.github.com"
  overwrite_on_create = true
}