# Variables
TERRAFORM_DIR=./Dev-Workspace/terraform-dev
ANSIBLE_DIR=./Dev-Workspace/ansible-dev
INVENTORY=d-inventory/aws_ec2.yml
PLAYBOOK=site.yml

.PHONY: deploy clean

deploy:
	@echo "Inicializando Terraform..."
	cd $(TERRAFORM_DIR) && terraform init

	@echo "Ejecutando terraform apply..."
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

	@echo "Esperando a que las instancias EC2 estén disponibles..."
	sleep 80

	@echo "Ejecutando ansible-playbook..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

clean:
	@echo "Destruyendo infraestructura con terraform..."
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve
