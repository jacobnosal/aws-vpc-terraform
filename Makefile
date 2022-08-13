default: docs

.PHONY: docs
docs: 
	cat README.md

make-docs:
	terraform-docs markdown table --output-file README.md --output-mode inject .