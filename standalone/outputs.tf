// file: standalone/outputs.tf

output "kubernaut_fqdn" { value = "${aws_route53_record.kubernaut.fqdn}" }

output "kubeadm_token" { value = "${data.template_file.kubeadm_token.rendered}" }
