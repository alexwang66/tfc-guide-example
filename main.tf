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

variable "jfrog_username" {
  description = "JFrog username (used for local execution)"
  type        = string
  default     = "alexwang"  # 或你本地使用的用户名
}

variable "jfrog_token" {
  description = "JFrog access token (used for local execution)"
  type        = string
  sensitive   = true
}
variable "tfc_credential_tag_name" {
  description = "The Terraform Cloud OIDC credential tag name"
  type        = string
  default     = "JFROG"
}

provider "platform" {
  url                     = var.jfrog_url
  oidc_provider_name      = "terraform-cloud"
  tfc_credential_tag_name = var.tfc_credential_tag_name
}

locals {
  use_oidc       = can(env("TFC_WORKLOAD_IDENTITY_TOKEN_JFROG"))
  helm_username  = local.use_oidc ? "oidc" : var.jfrog_username
  helm_password  = local.use_oidc ? env("TFC_WORKLOAD_IDENTITY_TOKEN_JFROG") : var.jfrog_token
}

resource "null_resource" "helm_repo_add" {
  provisioner "local-exec" {
    command = <<EOT
      echo "🔧 Checking Helm version..." > helm_exec.log
      helm version >> helm_exec.log 2>&1 || { echo "❌ Helm not found" >> helm_exec.log; echo "FAILED" > helm_status.log; exit 1; }

      echo "📦 Adding Helm repo '${var.jfrog_repo_name}'..." >> helm_exec.log
      helm repo add ${var.jfrog_repo_name} ${var.jfrog_helm_repo_url} \
        --username "${local.helm_username}" \
        --password "${local.helm_password}" >> helm_exec.log 2>&1

      if [ $? -ne 0 ]; then
        echo "❌ Failed to add Helm repo" >> helm_exec.log
        echo "FAILED" > helm_status.log
        exit 1
      else
        echo "✅ Helm repo added successfully" >> helm_exec.log
        echo "SUCCESS" > helm_status.log
      fi

      echo "🔄 Updating Helm repo cache..." >> helm_exec.log
      helm repo update >> helm_exec.log 2>&1
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

