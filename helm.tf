resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  namespace = aws_eks_pod_identity_association.aws_lbc.namespace

  set {
    name  = "clusterName"
    value = aws_eks_pod_identity_association.aws_lbc.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = aws_eks_pod_identity_association.aws_lbc.service_account
  }
}
