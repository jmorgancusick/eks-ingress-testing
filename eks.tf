module "eks_al2023" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "propel-ingress-al2023-arm"
  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  # EKS Addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    example = {
      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.small"]

      min_size = 2
      max_size = 5
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 2
    }
  }
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = module.eks_al2023.cluster_name
  namespace       = kubernetes_service_account.aws_lbc.metadata[0].namespace
  service_account = kubernetes_service_account.aws_lbc.metadata[0].name
  role_arn        = aws_iam_role.aws_lbc.arn
}
