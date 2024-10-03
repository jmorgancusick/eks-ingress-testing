resource "aws_iam_role" "aws_lbc" {
  name               = "aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.eks_pod_identity_trust_policy.json
}

resource "aws_iam_policy" "aws_lbc" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Permissions needed for AWS LBC"
  policy      = data.aws_iam_policy_document.aws_lbc_policy.json
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  role       = aws_iam_role.aws_lbc.name
  policy_arn = aws_iam_policy.aws_lbc.arn
}
