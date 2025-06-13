#!/bin/bash
####
### WIP rochmadsaputra@gmail.com
####

set -e

# Clone vllm repo if not exists
git clone https://github.com/vllm-project/vllm.git || true

# Clean and update repo
cd vllm
git clean -fdx || true
git checkout main || true
git submodule update --init --recursive || true

# Build Docker image
echo "Building Docker image... with command"
echo "docker build -f docker/Dockerfile.cpu -t sglang-cpu ."
docker build -f docker/Dockerfile.cpu -t sglang-cpu .


echo
echo "Building vLLM CPU environment complete."
echo
echo "To run the vLLM CPU environment, use the following command:"
echo
echo "For run based on sglang-cpu-entrypoint.sh (Qwen/Qwen2.5-0.5B-Instruct):"
echo "docker run -it -p 8000:8000 -v /root/.cache:/root/.cache --rm sglang-cpu ./entrypoint.sh"
echo
echo "For custom run for SGLANG CPU:"
echo "docker run -it -p 8000:8000 -v /root/.cache:/root/.cache --rm sglang-cpu /bin/bash"
echo "and execute the following command inside the container:"
echo "python -m sglang.launch_server --host 0.0.0.0 --port 8000 --device cpu --model-path Qwen/Qwen2.5-0.5B-Instruct"
echo
echo "For embedded mode:"
echo "python -m sglang.launch_server --host 0.0.0.0 --port 8000 --device cpu --model-path Qwen/Qwen3-Embedding-0.6B --is-embedding"
echo
echo "For custom run for VLLM CPU:"
echo "docker run -it -p 8000:8000 -v /root/.cache:/root/.cache --rm sglang-cpu /bin/bash"
echo "and execute the following command inside the container:"
echo "python3 -m vllm.entrypoints.openai.api_server --trust-remote-code --model Qwen/Qwen2.5-0.5B-Instruct"
echo
