// file: standalone/dns.tf

data "aws_route53_zone" "hosted_zone" {
  name = "${var.hosted_zone}"
}

resource "aws_route53_record" "kubernaut" {
  name    = "${lower("${var.cluster_name}.${data.aws_route53_zone.hosted_zone.name}")}"
  ttl     = 60
  type    = "CNAME"
  zone_id = "${data.aws_route53_zone.hosted_zone.id}"
  records = ["${aws_instance.kubernaut.public_dns}"]
}
