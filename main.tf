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
  oidc_provider_name = "jfrog-hkjc-tfc-nonprod"
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
echo "🔑 TFC_WORKLOAD_IDENTITY_TOKEN_JFROG="
echo "$${TFC_WORKLOAD_IDENTITY_TOKEN_JFROG}"

# 将 token 保存到单独的文件中
echo "$${TFC_WORKLOAD_IDENTITY_TOKEN_JFROG}" > token.txt

# 显示 token 的前20个字符（用于验证）
TOKEN_PREVIEW="$${TFC_WORKLOAD_IDENTITY_TOKEN_JFROG}"
if [ -n "$${TOKEN_PREVIEW}" ]; then
  echo "Token preview (first 20 chars): $${TOKEN_PREVIEW}" | cut -c1-20
else
  echo "Token preview: (empty)"
fi

# 检查 token 是否为空
if [ -z "$${TFC_WORKLOAD_IDENTITY_TOKEN_JFROG}" ]; then
  echo "❌ ERROR: TFC_WORKLOAD_IDENTITY_TOKEN_JFROG is empty!" >> curl_repo.log
  exit 1
else
  echo "✅ Token is present and not empty" >> curl_repo.log
fi

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

# 添加输出块来显示 token 信息
output "token_info" {
  description = "Information about the TFC workload identity token"
  value = {
    token_present = var.tfc_credential_tag_name != null
    token_preview = "Check token.txt file for full token"
    log_file = "curl_repo.log"
  }
}


