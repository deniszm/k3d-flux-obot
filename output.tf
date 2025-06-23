output "private_key_pem" {
  value     = module.tls_private_key.private_key_pem
  sensitive = true
}

output "public_key_openssh" {
  value     = module.tls_private_key.public_key_openssh
  sensitive = true
}