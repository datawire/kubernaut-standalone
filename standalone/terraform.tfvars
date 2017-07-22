cluster_name   = "plombardi"
hosted_zone    = "kubernaut.io"
instance_type  = "m4.large"
image_id       = "ami-14213c02"
ssh_public_key = "~/.ssh/plombardi_rsa.pub"

# Kubernetes Configuration
kubernetes_networking_plugin = "calico"