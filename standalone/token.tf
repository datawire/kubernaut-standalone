# token.tf
#
# Kubeadm uses a token to control nodes joining the master. While we do not need this feature right now it might be
# useful later so lets just generate one.
#
# Outputs the same format as `kubeadm token create` command: [a-z0-9]{6}.[a-z0-9]{16}
#

resource "random_shuffle" "kubeadm_token_part1" {
  input = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "t", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  result_count = 6
}

resource "random_shuffle" "kubeadm_token_part2" {
  input = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "t", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  result_count = 16
}

data "template_file" "kubeadm_token" {
  template = "$${part1}.$${part2}"

  vars {
    part1 = "${join("", random_shuffle.kubeadm_token_part1.result)}"
    part2 = "${join("", random_shuffle.kubeadm_token_part2.result)}"
  }
}
