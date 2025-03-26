
SETUP_DIR = ./setup

deploy:
	@echo "This action will delete the actual Droplet if created, including SSH key and database"
	@echo "Please 'make destroy' to clean properly"
	@echo "Continue ? (yes/no)"; \
	read answer; \
	if [ "$$answer" != "yes" ] && [ "$$answer" != "y" ]; then \
		echo "Aborting."; \
		exit 1; \
	fi
	cd $(SETUP_DIR) && \
	rm -rf id_rsa.pub id_rsa && \
	ssh-keygen -t rsa -b 4096 -f id_rsa -P "" && \
	chmod 600 id_rsa && chmod 644 id_rsa.pub && \
	ansible-galaxy collection install -r requirements.yml && \
	terraform init -upgrade && \
	terraform apply -auto-approve
	@echo "Droplet's IP stored in ./setup/hosts.ini"

destroy:
	cd $(SETUP_DIR) && \
	terraform destroy -auto-approve && \
	rm -rf id_rsa.pub id_rsa hosts.ini .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

ssh:
	@echo "Attempting SSH connection..."
	@if ! ssh $(shell grep -E '^DROPLET_USERNAME=[^[:space:]]+' .env | cut -d'=' -f2)@$(shell grep -A 1 '\[web\]' setup/hosts.ini | tail -n 1) -i setup/id_rsa; then \
		echo "Failed to connect.\nPlease make sure the droplet is deployed or you're on the root of the project"; \
		exit 1; \
	fi

.PHONY: deploy destroy ssh
