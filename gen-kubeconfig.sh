#!/bin/bash

# Input your API server URL and token
# API_SERVER_URL="https://<your-api-server>:<port>"
# TOKEN="<your-token>"

# Define the kubeconfig file path
if [ -z "$API_SERVER_URL" ] || [ -z "$TOKEN" ]; then
    echo "API_SERVER_URL and TOKEN must be set."
    exit 1
fi
if [ -z "$KUBECONFIG_FILE" ]; then
    KUBECONFIG_FILE="./kubeconfig.yaml"
fi

# Extract the hostname and port from the API server URL
HOST=$(echo $API_SERVER_URL | awk -F[/:] '{print $4}')
PORT=$(echo $API_SERVER_URL | awk -F[/:] '{print $5}')

if [ -z "$PORT" ]; then
  PORT=443
fi

# Fetch the CA certificate using openssl and Base64 encode it
CA_CERT=$(echo | openssl s_client -showcerts -servername $HOST -connect $HOST:$PORT 2>/dev/null \
    | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | base64 | tr -d '\n')

if [ -z "$CA_CERT" ]; then
    echo "Failed to fetch CA certificate."
    exit 1
fi

# Create the kubeconfig structure with embedded CA certificate
mkdir -p $(dirname $KUBECONFIG_FILE)

cat <<EOF > $KUBECONFIG_FILE
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: $API_SERVER_URL
    certificate-authority-data: $CA_CERT
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    user: default-user
  name: default-context
current-context: default-context
users:
- name: default-user
  user:
    token: $TOKEN
EOF

echo "Kubeconfig file created at $KUBECONFIG_FILE with embedded CA certificate."
