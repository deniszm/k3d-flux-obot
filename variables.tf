variable "tls_algorithm" {
  type        = string
  default     = "ECDSA"
  description = "The cryptographic algorithm (e.g. RSA, ECDSA)"
}

variable "tls_ecdsa_curve" {
  type        = string
  default     = "P256"
  description = "The elliptic curve (e.g. P256, P384, P521)"
}

variable "github_owner" {
  type        = string
  description = "The GitHub owner"
}

variable "github_token" {
  type        = string
  description = "GitHub personal access token"
}

variable "flux_github_repo" {
  type        = string
  default     = "flux-gitops"
  description = "GitHub repository"
}

variable "k3d_cluster_name" {
  type        = string
  description = "Name of the K3D cluster"
}

variable "k3d_agent_count" {
  type        = number
  description = "Number of K3D agent nodes"
}

variable "config_path" {
  type        = string
  default     = "~/.kube/config"
  description = "The path to the kubeconfig file"
}
