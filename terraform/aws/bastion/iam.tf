data "aws_iam_policy_document" "bastion_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  name               = "payflow-bastion-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.bastion_trust.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.bastion.name
}

data "aws_iam_policy_document" "eks_describe" {
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "eks_describe" {
  name   = "payflow-bastion-eks-describe-${var.environment}"
  role   = aws_iam_role.bastion.name
  policy = data.aws_iam_policy_document.eks_describe.json
}

resource "aws_iam_instance_profile" "bastion" {
  name = "payflow-bastion-profile-${var.environment}"
  role = aws_iam_role.bastion.name
}
