
SETUP_DIR = ./setup

all: help

help:
	@echo "make deploy          -> deploy a single droplet"
	@echo "make deploy d=DOMAIN -> Set a domain for your droplet(s)"
	@echo "- without this option, droplet(s) will be configured for ipv4 connections"
	@echo "make deploy n=NUMBER -> choose how many droplet's are created"
	@echo "- If a domain name is set, deploying more than 1 droplet will create subdomains like s1.domain.org, s2.domain.org, ..."
	@echo "make destroy         -> DESTROY EVERYTHING"
	@echo "make ssh             -> remote connection to the droplet with it's id (0 to NUMBER-1)"

deploy:
	@echo "This action will delete the actual Droplet(s) if created, including SSH keys and databases"
	@echo "Please 'make destroy' to clean properly"
	@echo "Continue ? (yes/no)"; \
	read answer; \
	if [ "$$answer" != "yes" ] && [ "$$answer" != "y" ]; then \
		echo "Aborting."; \
		exit 1; \
	fi
	cd $(SETUP_DIR) && \
	echo "[web]" > hosts.ini && \
	rm -rf id_rsa.pub id_rsa && \
	ssh-keygen -t rsa -b 4096 -f id_rsa -P "" && \
	chmod 600 id_rsa && chmod 644 id_rsa.pub && \
	ansible-galaxy collection install -r requirements.yml && \
	terraform init -upgrade && \
	terraform apply -auto-approve -var="droplet_count=$(or $(n), 1)" -var="domain_name=$(or $(d), "NODOMAIN")"
	@echo "Droplet's IP stored in ./setup/hosts.ini"

destroy:
	cd $(SETUP_DIR) && \
	terraform destroy -auto-approve && \
	rm -rf id_rsa.pub id_rsa hosts.ini .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

ssh:
	@echo "Droplet's id:"
	@echo "(0 to DROPLET_NUMBER)"; \
	read answer; \
	if [ -n "$$answer" ]; then \
		USERNAME=$$(grep -E '^DROPLET_USERNAME=[^[:space:]]+' .env | cut -d'=' -f2); \
		HOST=$$(awk "NR==$$answer+2" setup/hosts.ini | tail -n 1); \
		if test -z "$$USERNAME" -o -z "$$HOST"; then \
			echo "Invalid droplet ID or missing configuration in .env or setup/hosts.ini"; \
			exit 1; \
		fi; \
		echo "Connecting to $$USERNAME@$$HOST..."; \
		ssh "$$USERNAME@$$HOST" -i setup/id_rsa || { \
			echo "Failed to connect.\nPlease make sure the droplet is deployed or you're on the root of the project."; \
			exit 1; \
		}; \
	fi


.PHONY: deploy destroy ssh help
