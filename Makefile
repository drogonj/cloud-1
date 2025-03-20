
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
	terraform init -upgrade && \
	terraform apply -auto-approve
	@echo "Droplet's IP stored in ./setup/hosts.ini"

destroy:
	cd $(SETUP_DIR) && \
	terraform destroy -auto-approve && \
	rm -rf id_rsa.pub id_rsa .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

.PHONY: deploy destroy ssh
