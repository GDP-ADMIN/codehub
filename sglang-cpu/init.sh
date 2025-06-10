#!/bin/bash

echo "Building vLLM CPU environment..."
# This script sets up a Docker environment for running vLLM on CPU with specific configurations.
set -e
git submodule update --init --recursive

echo "Copying necessary files..."
cp Dockerfile.cpu-patched vllm/docker/Dockerfile.cpu
cp sglang-cpu/sglang-cpu-entrypoint.sh vllm/docker/sglang-cpu-entrypoint.sh

cd vllm

echo "Building vLLM CPU Docker image..."
docker build -f docker/Dockerfile.cpu -t sglang-cpu  .

echo "Building vLLM CPU environment complete."
echo "To run the vLLM CPU environment, use the following command:"
echo "docker run -it -p 8000:8000 -v /tmp/.cache:~/.cache --rm --network=host sglang-cpu /bin/bash"
echo "You can then start the server with the command:"

cd ../
