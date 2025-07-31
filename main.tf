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

resource "platform_oidc_configuration" "my-generic-oidc-configuration" {
  name          = "alex-tfc"  
  description   = "OIDC config for Terraform Cloud"
  issuer_url    = "https://app.terraform.io"
  provider_type = "generic"
  audience      = var.tfc_credential_tag_name  # 与 provider 匹配
}

provider "platform" {
  url = "https://hkjctest.jfrog.io"
  oidc_provider_name = "alex-tfc"
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

# 打印所有相关环境变量用于调试
echo "🔍 Debug: Checking environment variables..." >> curl_repo.log
echo "JFROG_URL: $${JFROG_URL}" >> curl_repo.log
echo "TFC_WORKLOAD_IDENTITY_TOKEN_JFROG: $${TFC_WORKLOAD_IDENTITY_TOKEN_JFROG}" >> curl_repo.log

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

# 检查 token 是否为空，但不退出，而是继续执行
if [ -z "$${TFC_WORKLOAD_IDENTITY_TOKEN_JFROG}" ]; then
  echo "⚠️  WARNING: TFC_WORKLOAD_IDENTITY_TOKEN_JFROG is empty!" >> curl_repo.log
  echo "This might be expected if running locally without Terraform Cloud OIDC setup" >> curl_repo.log
  echo "Continuing without authentication..." >> curl_repo.log
  
  # 尝试不带认证的请求
  curl -s "$${JFROG_URL}/artifactory/api/repositories" >> curl_repo.log 2>&1
else
  echo "✅ Token is present and not empty" >> curl_repo.log
  
  # 执行带认证的 curl 请求
  curl -s -H "Authorization: Bearer $${TFC_WORKLOAD_IDENTITY_TOKEN_JFROG}" \
    "$${JFROG_URL}/artifactory/api/repositories" >> curl_repo.log 2>&1
fi

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


