// file: standalone/outputs.tf

output "kubernaut_fqdn" { value = "${aws_route53_record.kubernaut.fqdn}" }