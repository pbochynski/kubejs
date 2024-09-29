#!/bin/bash

# Define the file paths
SERVER_JS_PATH="./server.js"
PACKAGE_JSON_PATH="./package.json"

# Check if the files exist
if [[ ! -f "$SERVER_JS_PATH" ]]; then
  echo "Error: $SERVER_JS_PATH does not exist."
  exit 1
fi

if [[ ! -f "$PACKAGE_JSON_PATH" ]]; then
  echo "Error: $PACKAGE_JSON_PATH does not exist."
  exit 1
fi

# Create the Deployment
kubectl apply -f deployment.yaml

# Create the ConfigMap
kubectl create configmap nodejs-config --from-file=server.js="$SERVER_JS_PATH" --from-file=package.json="$PACKAGE_JSON_PATH" --dry-run=client -o yaml | kubectl apply -f -

# Restart the Deployment
kubectl rollout restart deployment nodejs-deployment