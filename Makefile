.PHONY: help build push deploy test clean all

help:
	@echo "🚀 DevOps Platform - Available Commands"
	@echo ""
	@echo "Infrastructure:"
	@echo "  make infra-init     - Initialize Terraform"
	@echo "  make infra-plan     - Plan infrastructure"
	@echo "  make infra-apply    - Deploy infrastructure"
	@echo "  make infra-destroy  - Destroy infrastructure"
	@echo ""
	@echo "Application:"
	@echo "  make build          - Build Docker images"
	@echo "  make push           - Push images to Docker Hub"
	@echo "  make deploy         - Deploy to Kubernetes"
	@echo "  make test           - Run tests"
	@echo ""
	@echo "Kubernetes:"
	@echo "  make k8s-status     - Check cluster status"
	@echo "  make k8s-logs       - View application logs"
	@echo "  make k8s-shell      - Shell into backend pod"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean          - Delete application"
	@echo "  make clean-all      - Delete everything"

infra-init:
	cd terraform && terraform init

infra-plan:
	cd terraform && terraform plan

infra-apply:
	cd terraform && terraform apply -auto-approve
	@echo ""
	@echo "✅ Infrastructure deployed!"
	@echo "Master IP: $$(cd terraform && terraform output -raw master_public_ip)"

infra-destroy:
	cd terraform && terraform destroy -auto-approve

build:
	@echo "🐳 Building Docker images..."
	docker build -t asimkhankhitran/devops-backend:latest backend/
	docker build -t asimkhankhitran/devops-frontend:latest frontend/
	@echo "✅ Images built successfully"

push: build
	@echo "📤 Pushing images to Docker Hub..."
	docker push asimkhankhitran/devops-backend:latest
	docker push asimkhankhitran/devops-frontend:latest
	@echo "✅ Images pushed successfully"

deploy:
	@echo "🚀 Deploying to Kubernetes..."
	kubectl apply -f k8s/base/
	@echo "⏳ Waiting for deployments..."
	kubectl wait --for=condition=ready pod -l app=backend -n devops-app --timeout=300s
	kubectl wait --for=condition=ready pod -l app=frontend -n devops-app --timeout=300s
	@echo "✅ Application deployed successfully"
	@echo ""
	@echo "Access application at:"
	@echo "http://$$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}'):$$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')"

test:
	@echo "🧪 Running tests..."
	cd backend && pytest ../tests/ -v
	@echo "✅ All tests passed"

k8s-status:
	@echo "📊 Cluster Status:"
	kubectl get nodes -o wide
	@echo ""
	@echo "📦 Application Pods:"
	kubectl get pods -n devops-app -o wide
	@echo ""
	@echo "🌐 Services:"
	kubectl get svc -n devops-app
	@echo ""
	@echo "🔀 Ingress:"
	kubectl get ingress -n devops-app

k8s-logs:
	@echo "📋 Backend Logs:"
	kubectl logs -n devops-app -l app=backend --tail=50
	@echo ""
	@echo "📋 Frontend Logs:"
	kubectl logs -n devops-app -l app=frontend --tail=50

k8s-shell:
	kubectl exec -it -n devops-app deployment/backend -- /bin/sh

clean:
	@echo "🧹 Cleaning up application..."
	kubectl delete namespace devops-app --ignore-not-found=true
	@echo "✅ Application deleted"

clean-all: clean infra-destroy
	@echo "✅ Everything cleaned up"

all: infra-apply build push deploy
	@echo "🎉 Complete deployment finished!"
