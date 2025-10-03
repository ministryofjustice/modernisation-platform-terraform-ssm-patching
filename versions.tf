terraform {
  required_providers {
    aws = {
      version               = ">= 5.100"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.bucket-replication]
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
  required_version = "~> 1.10"
}
