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
  echo "📦 Fetching repository list from ${var.jfrog_url}..." > curl_repo.log

  curl -s -w "%%{http_code}" -o curl_repo.json \
    -H "Authorization: Bearer $TFC_WORKLOAD_IDENTITY_TOKEN_JFROG" \
    "${var.jfrog_url}/artifactory/api/repositories?type=local" > curl_status_code.txt

  STATUS=$(cat curl_status_code.txt)

  if [ "$STATUS" -eq "200" ]; then
    echo "✅ Repository list fetched successfully." >> curl_repo.log
    echo "SUCCESS" > curl_status_flag.log
  else
    echo "❌ Failed to fetch repositories. HTTP $STATUS" >> curl_repo.log
    echo "FAILED" > curl_status_flag.log
    exit 1
  fi
EOT

  }

  triggers = {
    always_run = timestamp()
  }
}




