#!/bin/bash
set -e

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <service>"
  echo "Available options: opensearch"
  exit 1
fi

SERVICE=$1

if [ "$SERVICE" == "opensearch" ]; then
  echo "Starting OpenSearch setup..."

  if [ -f ./opensearch/server/standalone-cluster/install.sh ]; then
    echo "Running install.sh in standalone-cluster..."
    (cd ./opensearch/server/standalone-cluster && ./install.sh)
  else
    echo "install.sh not found in standalone-cluster. Please ensure that all files are fully pulled from the repository..."
  fi

  if [ -f ./opensearch/client/filebeat-agent/install.sh ]; then
    echo "Running install.sh in filebeat-agent..."
    (cd ./opensearch/client/filebeat-agent && ./install.sh)
  else
    echo "install.sh not found in filebeat-agent. Please ensure that all files are fully pulled from the repository..."
  fi

else
  echo "Invalid service option: $SERVICE"
  echo "Available options: opensearch"
  exit 1
fi

if [ -f ./sample-app/install.sh ]; then
  echo "Running install.sh in sample-app..."
  (cd ./sample-app && ./install.sh)
else
  echo "install.sh not found in sample-app. Please ensure that all files are fully pulled from the repository..."
fi

echo "All installation scripts have been executed successfully."
echo "Access your opensearch dashboard at http://localhost:5601/app/data-explorer/discover#?_a=(discover:(columns:!(_source),isDirty:!f,sort:!()),metadata:(indexPattern:Logs,view:discover))&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-15m,to:now))&_q=(filters:!(),query:(language:kuery,query:''))"
