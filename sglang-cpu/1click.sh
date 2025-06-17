#!/bin/bash
####
### WIP rochmadsaputra@gmail.com
####

set -xe
current_dir=$PWD
cd /tmp
git clone git@github.com:GDP-ADMIN/codehub.git || true
git checkout sglang-cpu || true
cd codehub/sglang-cpu 
git clean -fdx || true
git submodule update --init --recursive || true

# Clean and update repo
cd vllm
git clean -fdx || true
git checkout main || true

cp  ../Dockerfile.cpu-patched docker/Dockerfile.cpu
cp  ../sglang-cpu-entrypoint.sh docker/sglang-cpu-entrypoint.sh

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
