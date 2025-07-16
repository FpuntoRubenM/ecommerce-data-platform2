# Makefile para E-commerce Data Platform
# Autor: Ruben Martin

.PHONY: help init plan apply destroy validate fmt lint test clean

# Variables
ENV ?= dev
TF_VAR_FILE ?= terraform.tfvars

help: ## Mostrar ayuda
@echo "E-commerce Data Platform - Ruben Martin"
@echo ""
@echo "Comandos disponibles:"
@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Inicializar Terraform
terraform init

validate: ## Validar configuración Terraform
terraform validate

fmt: ## Formatear código Terraform
terraform fmt -recursive

lint: ## Ejecutar linting con tflint
tflint --init
tflint

plan: ## Planificar despliegue
terraform plan -var="environment=$(ENV)" -var-file="$(TF_VAR_FILE)"

apply: ## Aplicar infraestructura
terraform apply -var="environment=$(ENV)" -var-file="$(TF_VAR_FILE)"

destroy: ## Destruir infraestructura
terraform destroy -var="environment=$(ENV)" -var-file="$(TF_VAR_FILE)"

test: ## Ejecutar tests
python -m pytest tests/ -v

clean: ## Limpiar archivos temporales
rm -rf .terraform
rm -f *.tfplan
rm -f *.tfstate*

dev: ## Desplegar entorno de desarrollo
$(MAKE) plan ENV=dev
$(MAKE) apply ENV=dev

prod: ## Desplegar entorno de producción (requiere confirmación)
@echo "⚠️  Vas a desplegar en PRODUCCIÓN ⚠️"
@read -p "¿Estás seguro? (y/N): " confirm && [ "$$confirm" = "y" ]
$(MAKE) plan ENV=prod
$(MAKE) apply ENV=prod

status: ## Mostrar estado de la infraestructura
terraform show

outputs: ## Mostrar outputs de Terraform
terraform output
