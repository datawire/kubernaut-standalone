# file: vpc.tf

resource "aws_vpc" "kubernaut" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name                       = "kubernaut-${var.cluster_name}"
    "io.kubernaut/ClusterName" = "${var.cluster_name}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.kubernaut.id}"

  tags {
    Name                       = "kubernaut-${var.cluster_name}"
    "io.kubernaut/ClusterName" = "${var.cluster_name}"
  }
}

resource "aws_subnet" "kubernaut" {
  cidr_block = "10.10.0.0/20"
  vpc_id     = "${aws_vpc.kubernaut.id}"

  tags {
    Name                       = "kubernaut-${var.cluster_name}"
    "io.kubernaut/ClusterName" = "${var.cluster_name}"
  }
}

resource "aws_route_table_association" "kubernaut" {
  subnet_id      = "${aws_subnet.kubernaut.id}"
  route_table_id = "${aws_vpc.kubernaut.default_route_table_id}"
}
