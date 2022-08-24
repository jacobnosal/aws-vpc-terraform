output "private_key_pem" {
  description = "(String, Sensitive) Private key data in PEM (RFC 1421) format."
  value = tls_private_key.public_vm_0.private_key_pem
  sensitive = true
}

output "public_key_pem" {
  description = "(String) Public key data in PEM (RFC 1421) format. NOTE: the underlying libraries that generate this value append a \n at the end of the PEM. In case this disrupts your use case, we recommend using trimspace()."
  value = tls_private_key.public_vm_0.public_key_pem
}

output "ssh_private_key" {
  description = "(String, Sensitive) Private key data in OpenSSH PEM (RFC 4716) format."
  value = tls_private_key.public_vm_0.private_key_openssh
  sensitive = true
}

output "ssh_public_key" {
  description = "(String) The public key data in \"Authorized Keys\" format. This is not populated for ECDSA with curve P224, as it is not supported. NOTE: the underlying libraries that generate this value append a \n at the end of the PEM. In case this disrupts your use case, we recommend using trimspace()."
  value = tls_private_key.public_vm_0.public_key_openssh
}

output "public_vm_0_ip" {
  description = "The public IP address assigned to the instance, if applicable. NOTE: If you are using an aws_eip with your instance, you should refer to the EIP's address directly and not use public_ip as this field will change after the EIP is attached."
  value = aws_instance.public_vm_0.public_ip
}

output "private_vm_0_ip" {
  description = ""
  value = aws_instance.private_vm_0.private_ip
}