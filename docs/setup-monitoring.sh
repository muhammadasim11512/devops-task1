#!/bin/bash
set -e

echo "Installing Prometheus and Grafana..."

kubectl create namespace monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s

echo "Getting Grafana password..."
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
echo ""

echo "Port forward Grafana:"
echo "kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo ""
echo "Access Grafana at http://localhost:3000"
echo "Username: admin"
