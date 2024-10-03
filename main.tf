provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region

  default_tags {
    tags = {
      owner = var.owner
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

terraform {
  backend "s3" {
    bucket  = "jmorgancusick-terraform-state-sandbox"
    key     = "global/eks-ingress-testing/terraform.tfstate"
    region  = "us-east-1"
    profile = "personal"

    dynamodb_table = "jmorgancusick-terraform-state-lock-sandbox"
    encrypt        = true
  }
}
