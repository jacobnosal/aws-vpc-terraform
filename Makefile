default: docs

.PHONY: docs
docs: 
	cat README.md

make-docs:
	terraform-docs markdown table --output-file README.md --output-mode inject .

ssh-to-public-vm:
	ssh -i public_vm_0_ssh_private.key ec2-user@$(terraform output -raw public_vm_0_ip)