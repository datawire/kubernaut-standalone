# file: standalone/iam.tf

resource "aws_iam_policy" "kubernaut_policy" {
  name        = "kubernaut-${var.cluster_name}"
  path        = "/"
  description = "Policy for Kubernaut role ${var.cluster_name}"
  policy      = "${file("${path.module}/iam/policy.json")}"
}

resource "aws_iam_role" "kubernaut_role" {
  name               = "kubernaut-${var.cluster_name}"
  description        = "Role for Kubernaut ${var.cluster_name}"
  assume_role_policy = "${file("${path.module}/iam/role.json")}"
}

resource "aws_iam_policy_attachment" "kubernaut-attach" {
  name       = "kubernaut-attachment"
  roles      = ["${aws_iam_role.kubernaut_role.name}"]
  policy_arn = "${aws_iam_policy.kubernaut_policy.arn}"
}

resource "aws_iam_instance_profile" "kubernaut_profile" {
  name = "${var.cluster_name}"
  role = "${aws_iam_role.kubernaut_role.name}"
}
