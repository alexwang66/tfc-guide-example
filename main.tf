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

resource "null_resource" "jfrog_repo_check" {
  provisioner "local-exec" {
    command = <<EOT
echo "📦 Fetching repository list from $${JFROG_URL}..." > curl_repo.log

# 打印 token 到日志（仅用于调试，生产中请小心）
echo "🔑 TFC_WORKLOAD_IDENTITY_TOKEN_JFROG=" >> curl_repo.log
echo "$${TFC_WORKLOAD_IDENTITY_TOKEN_JFROG}" >> curl_repo.log

# 执行 curl 请求并记录输出
curl -s -H "Authorization: Bearer $${TFC_WORKLOAD_IDENTITY_TOKEN_JFROG}" \
  "$${JFROG_URL}/artifactory/api/repositories" >> curl_repo.log 2>&1

echo "✅ Finished fetching repositories." >> curl_repo.log
EOT
  }

  triggers = {
    always_run = timestamp()
  }
}


