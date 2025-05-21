resource "digitalocean_droplet" "cluster" {
  for_each  = { for s in local.servers : s.name => s }
  name      = each.value.name
  region    = var.region
  size      = var.size
  image     = "ubuntu-20-04-x64"
  tags      = each.value.tags
  ssh_keys  = var.ssh_key_ids
  user_data = <<-EOT
#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin, sudo
    shell: /bin/bash
    ssh_authorized_keys:
      ${join("\n      - ", var.ubuntu_user_public_keys)}
EOT
}
