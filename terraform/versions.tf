terraform {
  backend "s3" {
    # 機密情報の漏洩防止の為、bucket は -backend-config オプションで指定すること
    key = "tfstate.d/codepipeline-tutorial/terraform.tfstate.json"
    region = "ap-northeast-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      Environment = "develop"
      ManagedBy   = "terraform"
    }
  }
}
