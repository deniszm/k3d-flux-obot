# k3d-flux-obot

This project sets up a local development environment with K3D cluster and Flux GitOps for automatic application deployment.

## Overview

The infrastructure includes:
- **K3D cluster** - Local Kubernetes cluster for development and testing
- **Flux GitOps** - Automated deployment and synchronization from Git repositories
- **TLS keys** - Secure authentication between Flux and GitHub
- **GitHub integration** - Automatic repository setup with deploy keys
- **Application deployment** - Automated deployment of obot application via Helm

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          GitHub                                 │
│  ┌─────────────────────┐    ┌─────────────────────────────────┐ │
│  │   flux-gitops       │    │           obot                  │ │
│  │  ├── clusters/      │    │  ├── helm/                      │ │
│  │  └── flux-system/   │    │  ├── Dockerfile                 │ │
│  └─────────────────────┘    │  └── main.go                    │ │
│                             └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
           │                                    │
           │ SSH                                │ HTTPS
           │                                    │
           v                                    v
┌─────────────────────────────────────────────────────────────────┐
│                       K3D Cluster                               │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                 flux-system                             │    │
│  │  ├── source-controller                                  │    │
│  │  ├── helm-controller                                    │    │
│  │  └── SSH keys                                           │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                  │
│                              v                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                 GitRepository CRD                       │    │
│  │  name: obot                                             │    │
│  │  url: github.com/deniszm/obot                           │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                  │
│                              v                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                 HelmRelease CRD                         │    │
│  │  name: obot                                             │    │
│  │  chart: helm/                                           │    │
│  │  namespace: default                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                  │
│                              v                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   default                               │    │
│  │  └── obot Pod(s)                                        │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Workflow

```
Developer → obot repo → GitHub Actions → Helm chart update
                                                │
Flux (1m) ←─────────────────────────────────────┘
   │
   └── Detects changes → Deploys to K3D → obot running
```

## Prerequisites

- Docker installed and running
- Terraform >= 1.0
- GitHub personal access token with repo permissions
- K3D CLI tool

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <this-repo>
   cd k3d-flux-obot
   ```

2. **Configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your GitHub settings
   ```

3. **Deploy infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Verify deployment**
   ```bash
   # Get kubeconfig
   k3d kubeconfig get flux-obot
   
   # Check Flux controllers
   kubectl get pods -n flux-system
   
   # Check obot deployment
   kubectl get pods -n default
   kubectl get gitrepositories,helmreleases -A
   ```

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `github_owner` | GitHub username/organization | `deniszm` |
| `github_token` | GitHub personal access token | `ghp_xxxxx` |
| `k3d_cluster_name` | Name for K3D cluster | `flux-obot` |
| `k3d_agent_count` | Number of worker nodes | `3` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `flux_github_repo` | `flux-gitops` | Repository for Flux manifests |
| `tls_algorithm` | `ECDSA` | Algorithm for TLS keys |
| `tls_ecdsa_curve` | `P256` | ECDSA curve for keys |

## What Gets Created

### Infrastructure
- K3D cluster with specified number of agents
- Flux controllers installed in `flux-system` namespace
- GitHub repository for GitOps with deploy key
- TLS key pair for secure Git authentication

### Application Deployment
- GitRepository CRD pointing to `https://github.com/deniszm/obot`
- HelmRelease CRD deploying obot from `helm/` directory
- obot application running in `default` namespace

### Generated Files
The following files are automatically created in your flux-gitops repository:
- `clusters/local/obot-gitrepository.yaml`
- `clusters/local/obot-helmrelease.yaml`

## GitOps Workflow

1. **Code Change** → Push to obot repository
2. **CI/CD Pipeline** → Build new container image and update Helm chart
3. **Flux Detection** → Flux detects changes in obot repository
4. **Automatic Deployment** → Flux updates obot deployment in K3D cluster

## Useful Commands

```bash
# Check cluster status
k3d cluster list
kubectl cluster-info

# Monitor Flux
flux get sources git
flux get helmreleases
flux logs --follow

# Debug obot deployment
kubectl logs -l app=obot
kubectl describe helmrelease obot

# Access obot (if service is exposed)
kubectl port-forward svc/obot 8080:80
```

## Troubleshooting

### Flux not syncing
```bash
# Check Flux controllers
kubectl get pods -n flux-system

# Check source controller logs
kubectl logs -n flux-system deployment/source-controller

# Force reconciliation
flux reconcile source git obot
```

### obot not deploying
```bash
# Check HelmRelease status
kubectl describe helmrelease obot

# Check Helm controller logs
kubectl logs -n flux-system deployment/helm-controller
```

### GitHub authentication issues
```bash
# Check if deploy key is added to repository
# Verify private key in cluster
kubectl get secret -n flux-system
```

## Cleanup

```bash
# Destroy infrastructure
terraform destroy

# Remove K3D cluster (if needed)
k3d cluster delete flux-obot
```

## Project Structure

```
.
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── terraform.tfvars     # Variable values (not in git)
├── output.tf            # Output definitions
└── README.md           # This file
```

## Modules Used

- [tf-hashicorp-tls-keys](https://github.com/deniszm/tf-hashicorp-tls-keys) - TLS key generation
- [tf-github-repository](https://github.com/deniszm/tf-github-repository) - GitHub repo setup
- [tf-k3d-cluster](https://github.com/deniszm/tf-k3d-cluster) - K3D cluster creation
- [tf-fluxcd-flux-bootstrap](https://github.com/deniszm/tf-fluxcd-flux-bootstrap) - Flux installation

## License

This project is licensed under the MIT License.