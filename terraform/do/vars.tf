variable "do_token" {
  type = string
  description = "DigitalOcean API token"
  sensitive = true
}
variable "region"   { 
	default = "nyc3"
	description = "DigitalOcean region"
}
variable "size"     { 
	default = "s-1vcpu-1gb"
	description = "DigitalOcean size"
}
variable "ssh_key_ids" { 
	type = list(string)
	description = "DigitalOcean SSH key Fingerprints"
}
variable "ubuntu_user_public_keys" {
  type        = list(string)
  description = "List of public keys for the ubuntu user"
  default = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJmkkh2Cr2Jz2hX1Oq0i++Yk9Vfq9ZPk5DyUCKakHSWg"]
}
