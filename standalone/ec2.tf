# file: standalone/ec2.tf

resource "aws_security_group" "kubernaut" {
  vpc_id = "${aws_vpc.kubernaut.id}"
  name   = "${var.cluster_name}"

  tags {
    "io.kubernaut/ClusterName" = "${var.cluster_name}"
  }
}

resource "aws_security_group_rule" "all_self" {
  self              = true
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  security_group_id = "${aws_security_group.kubernaut.id}"
  type              = "ingress"
}

resource "aws_security_group_rule" "ssh" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.kubernaut.id}"
  type              = "ingress"
}

resource "aws_security_group_rule" "api_server" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.kubernaut.id}"
  type              = "ingress"
}

resource "aws_security_group_rule" "all_egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  security_group_id = "${aws_security_group.kubernaut.id}"
  type              = "egress"
}

data "template_file" "kubernaut_provisioner" {
  template = "${file("${path.module}/provision.sh")}"

  vars {
    kubeadm_token                = "${data.template_file.kubeadm_token.rendered}"
    cluster_name                 = "${var.cluster_name}"
    cluster_dns_name             = "${var.cluster_name}.${var.hosted_zone}"
    kubernetes_networking_plugin = "${var.kubernetes_networking_plugin}"
  }
}

resource "aws_key_pair" "kubernaut" {
  key_name_prefix = "kubernaut-${var.cluster_name}-"
  public_key      = "${file(pathexpand(var.ssh_public_key))}"
}

resource "aws_instance" "kubernaut" {
  ami                         = "${var.image_id}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.kubernaut_profile.name}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${aws_subnet.kubernaut.id}"
  user_data                   = "${data.template_file.kubernaut_provisioner.rendered}"
  key_name                    = "${aws_key_pair.kubernaut.id}"
  vpc_security_group_ids      = ["${aws_security_group.kubernaut.id}"]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "20"
    delete_on_termination = true
  }

  tags {
    Name                       = "kubernaut-${var.cluster_name}"
    "io.kubernaut/ClusterName" = "${var.cluster_name}"
  }
}
