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

variable "tfc_credential_tag_name" {
  description = "The Terraform Cloud OIDC credential tag name"
  type        = string
  default     = "JFROG"
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
  default     = "alexwang"
}

resource "null_resource" "helm_repo_add" {
  provisioner "local-exec" {
    command = <<EOT
      echo "🔧 Checking Helm version..."
      helm version || { echo "❌ Helm is not installed or not working."; exit 1; }

      echo "📦 Adding Helm repo: ${var.jfrog_repo_name}"
      echo "$JFROG_OIDC_TOKEN" > /tmp/jfrog_oidc_token.jwt
      helm repo add ${var.jfrog_repo_name} ${var.jfrog_helm_repo_url} \
        --username "alexwang" \
        --password "$JFROG_OIDC_TOKEN"

      if [ $? -ne 0 ]; then
        echo "❌ Failed to add Helm repo!"
        exit 1
      else
        echo "✅ Helm repo '${var.jfrog_repo_name}' added successfully."
      fi

      echo "🔄 Updating Helm repo cache..."
      helm repo update

      if [ $? -ne 0 ]; then
        echo "❌ Helm repo update failed!"
        exit 1
      else
        echo "✅ Helm repo update successful."
      fi
    EOT
  }
}
