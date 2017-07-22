variable "cluster_name" {}
variable "hosted_zone" {}
variable "instance_type" {}
variable "image_id" {}

variable "region" {
  default = "us-east-1"
}

variable "ssh_public_key" {}

variable "kubernetes_networking_plugin" {
  description = "Name of the Kubernetes networking plugin"
  default     = "calico"
}
