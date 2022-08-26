default: docs

.PHONY: docs
docs: 
	cat README.md

make-docs:
	terraform-docs markdown table --output-file README.md --output-mode inject .

get-key:
	terraform output -raw ssh_private_key > public_vm_0_ssh.pem