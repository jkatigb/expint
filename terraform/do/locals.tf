locals {
  servers = [
    { name = "web1", tags = ["web","internal"] },
    { name = "web2", tags = ["web","internal"] },
    { name = "lb",   tags = ["lb","public"]    },
    { name = "mon",  tags = ["mon","internal"] }
  ]
}