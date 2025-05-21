output "inventory_ini" {
  value = templatefile("${path.module}/templates/inventory.tpl",
    { droplets = digitalocean_droplet.cluster })
}