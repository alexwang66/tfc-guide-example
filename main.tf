terraform {
  cloud {
    organization = "alexwang"
    workspaces {
      name = "tfc-guide-example"
    }
  }

  required_providers {
    platform = {
      source  = "jfrog/platform"
      version = "2.2.5"
    }
  }
}

provider "platform" {
  url = "https://hkjctest.jfrog.io"
  oidc_provider_name = "terraform-cloud"
  tfc_credential_tag_name = "JFROG"
}

variable "jfrog_url" {
  description = "JFrog Artifactory base URL"
  type        = string
}

variable "jfrog_repo_name" {
  description = "Name to assign to the Helm repo"
  type        = string
}

variable "jfrog_helm_repo_url" {
  description = "JFrog Helm repository URL"
  type        = string
}

variable "jfrog_username" {
  description = "JFrog username"
  type        = string
}

variable "jfrog_token" {
  description = "JFrog access token or password"
  type        = string
  sensitive   = true
}

resource "null_resource" "helm_repo_add" {
  provisioner "local-exec" {
    environment = {
      JFROG_OIDC_TOKEN = "TFC_WORKLOAD_IDENTITY_TOKEN_JFROG"
    }

    command = <<EOT
      echo "$JFROG_OIDC_TOKEN" > /tmp/jfrog_oidc_token.jwt
      helm repo add ${var.jfrog_repo_name} ${var.jfrog_helm_repo_url} \
        --username "oidc" \
        --password "$JFROG_OIDC_TOKEN"
    EOT
  }
}

