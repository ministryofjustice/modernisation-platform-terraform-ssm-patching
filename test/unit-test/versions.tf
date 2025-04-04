terraform {
  required_providers {
    aws = {
      version = "~> 5.90"
      source  = "hashicorp/aws"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
  required_version = "~> 1.10"
}
