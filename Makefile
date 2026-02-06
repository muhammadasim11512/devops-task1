.PHONY: help build push deploy test clean

help:
	@echo "Available targets:"
	@echo "  build       - Build Docker images"
	@echo "  push        - Push images to Docker Hub"
	@echo "  deploy      - Deploy to Kubernetes"
	@echo "  test        - Run tests"
	@echo "  clean       - Clean up resources"

build:
	docker build -t asimkhankhitran/devops-backend:latest backend/
	docker build -t asimkhankhitran/devops-frontend:latest frontend/

push:
	docker push asimkhankhitran/devops-backend:latest
	docker push asimkhankhitran/devops-frontend:latest

deploy:
	kubectl apply -f k8s/base/

test:
	pytest tests/ -v

clean:
	kubectl delete namespace devops-app

terraform-init:
	cd terraform && terraform init

terraform-plan:
	cd terraform && terraform plan

terraform-apply:
	cd terraform && terraform apply -auto-approve

terraform-destroy:
	cd terraform && terraform destroy -auto-approve
