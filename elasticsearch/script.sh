#!/bin/sh

# Install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
unset https_proxy
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Generate certificate
mkdir certs
elasticsearch-certutil ca --out certs/elastic-stack-ca.p12 --pass ''
elasticsearch-certutil cert --name security-master --dns security-master --ca certs/elastic-stack-ca.p12 --pass '' --ca-pass '' --out certs/elastic-certificates.p12

# Create secret in kube
./kubectl delete secret elasticsearch-certificates
./kubectl create secret generic elasticsearch-certificates --from-file=certs/elastic-certificates.p12