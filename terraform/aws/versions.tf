terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    sonarqube = {
      source  = "jdamata/sonarqube"
      version = "~> 0.16"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "sonarqube" {
  host = "http://${data.aws_instances.nodes.public_ips[0]}:30900"
  user = "admin"
  pass = var.sonarqube_admin_password
}
