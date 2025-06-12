# sglang-cpu: Running SGlang and vLLM on CPU with Docker

This guide provides instructions for building and running the SGlang language server and vLLM on an x86 CPU platform using Docker. It includes a ready-to-use Dockerfile, entrypoint script, and example commands for launching the server with a pre-trained model. The setup is intended for users who want to deploy or develop SGlang and vLLM without GPU support.


## 1. Clone vllm Repository
```bash
gitt clone https://github.com/vllm-project/vllm.git || true
cd vllm
```
## 2. edit file Dockerfile.cpu
edit docker/Dockerfile.cpu
```bash
# This vLLM Dockerfile is used to construct image that can build and run vLLM on x86 CPU platform.
#
# Build targets:
#   vllm-openai (default): used for serving deployment
#   vllm-test: used for CI tests
#   vllm-dev: used for development
#
# Build arguments:
#   PYTHON_VERSION=3.12 (default)|3.11|3.10|3.9
#   VLLM_CPU_DISABLE_AVX512=false (default)|true
#

######################### BASE IMAGE #########################
FROM ubuntu:22.04 AS base

WORKDIR /workspace/

ARG PYTHON_VERSION=3.12
ARG PIP_EXTRA_INDEX_URL="https://download.pytorch.org/whl/cpu"

ENV LD_PRELOAD=""

# Install minimal dependencies and uv
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -y \
    && apt-get install -y --no-install-recommends ccache git curl wget ca-certificates \
        gcc-12 g++-12 libtcmalloc-minimal4 libnuma-dev ffmpeg libsm6 libxext6 libgl1 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 10 --slave /usr/bin/g++ g++ /usr/bin/g++-12 \
    && curl -LsSf https://astral.sh/uv/install.sh | sh

ENV CCACHE_DIR=/root/.cache/ccache
ENV CMAKE_CXX_COMPILER_LAUNCHER=ccache

ENV PATH="/root/.local/bin:$PATH"
ENV VIRTUAL_ENV="/opt/venv"
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python
RUN uv venv --python ${PYTHON_VERSION} --seed ${VIRTUAL_ENV}
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

ENV UV_HTTP_TIMEOUT=500

# Install Python dependencies
ENV PIP_EXTRA_INDEX_URL=${PIP_EXTRA_INDEX_URL}
ENV UV_EXTRA_INDEX_URL=${PIP_EXTRA_INDEX_URL}
ENV UV_INDEX_STRATEGY="unsafe-best-match"
ENV UV_LINK_MODE="copy"
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,src=requirements/common.txt,target=requirements/common.txt \
    --mount=type=bind,src=requirements/cpu.txt,target=requirements/cpu.txt \
    uv pip install --upgrade pip && \
    uv pip install -r requirements/cpu.txt

ENV LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4:/opt/venv/lib/libiomp5.so:$LD_PRELOAD"

RUN echo 'ulimit -c 0' >> ~/.bashrc

######################### BUILD IMAGE #########################
FROM base AS vllm-build

ARG GIT_REPO_CHECK=0
# Support for building with non-AVX512 vLLM: docker build --build-arg VLLM_CPU_DISABLE_AVX512="true" ...
ARG VLLM_CPU_DISABLE_AVX512
ENV VLLM_CPU_DISABLE_AVX512=${VLLM_CPU_DISABLE_AVX512}

WORKDIR /workspace/vllm

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,src=requirements/build.txt,target=requirements/build.txt \
    uv pip install -r requirements/build.txt

COPY . .
RUN --mount=type=bind,source=.git,target=.git \
    if [ "$GIT_REPO_CHECK" != 0 ]; then bash tools/check_repo.sh ; fi

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=cache,target=/root/.cache/ccache \
    --mount=type=cache,target=/workspace/vllm/.deps,sharing=locked \
    --mount=type=bind,source=.git,target=.git \
    VLLM_TARGET_DEVICE=cpu python3 setup.py bdist_wheel

######################### DEV IMAGE #########################
FROM vllm-build AS vllm-dev

WORKDIR /workspace/vllm

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get install -y --no-install-recommends vim numactl xz-utils

# install development dependencies (for testing)
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install -e tests/vllm_test_utils

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=cache,target=/root/.cache/ccache \
    --mount=type=bind,source=.git,target=.git \
    VLLM_TARGET_DEVICE=cpu python3 setup.py develop

RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install -r requirements/dev.txt && \
    pre-commit install --hook-type pre-commit --hook-type commit-msg

ENTRYPOINT ["bash"]

######################### TEST IMAGE #########################
FROM base AS vllm-test

WORKDIR /workspace/

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,src=requirements/test.in,target=requirements/test.in \
    cp requirements/test.in requirements/test-cpu.in && \
    sed -i '/mamba_ssm/d' requirements/test-cpu.in && \
    uv pip compile requirements/test-cpu.in -o requirements/cpu-test.txt && \
    uv pip install -r requirements/cpu-test.txt


RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,from=vllm-build,src=/workspace/vllm/dist,target=dist \
    uv pip install dist/*.whl

ADD ./tests/ ./tests/
ADD ./examples/ ./examples/
ADD ./benchmarks/ ./benchmarks/
ADD ./vllm/collect_env.py .

# install development dependencies (for testing)
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install -e tests/vllm_test_utils

ENTRYPOINT ["bash"]

######################### RELEASE IMAGE #########################
FROM base AS vllm-openai

WORKDIR /workspace/

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=cache,target=/root/.cache/ccache \
    --mount=type=bind,from=vllm-build,src=/workspace/vllm/dist,target=dist \
    uv pip install dist/*.whl && \
    uv pip install torch==2.7.0+cpu torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu


#    uv pip install "sglang[all]>=0.4.6.post5" && \

RUN apt-get update && apt-get install gpg -f -y
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main" >> /etc/apt/sources.list && apt update && \
    apt-get update && apt-get install build-essential cmake nano make -f -y

RUN git clone https://github.com/sgl-project/sglang.git || true && \
    cd sglang && pip install -e "python[all_cpu]" && \
    cd sgl-kernel/ && \
    cp pyproject_cpu.toml pyproject.toml && \
    pip install -v .
#PATCH
RUN sed -i.bak '/if not model_config.enforce_eager:/ s/^/#/; /model_config.enforce_eager = True/ s/^/#/' /opt/venv/lib/python3.12/site-packages/vllm/platforms/cpu.py
RUN sed -i.bak '/model_config.disable_cascade_attn = True/s/^/#/' /opt/venv/lib/python3.12/site-packages/vllm/platforms/cpu.py


#ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
# Set environment for non-interactive mode
ENV PYTHONUNBUFFERED=1

COPY docker/sglang-cpu-entrypoint.sh ./entrypoint.sh
RUN chmod +x entrypoint.sh

# Copy the rest of your application code
# Set the entrypoint for the container
#ENTRYPOINT ["./entrypoint.sh"]

# Optionally define CMD if you expect to override specific parameters
# CMD ["--additional-arg", "value"]  # Uncomment if you want to use CMD for overrides
```


## 3. add docker/sglang-cpu-entrypoint.sh
```bash
#!/bin/bash
# entrypoint.sh

# Execute the server launch command with parameters
python3 -m sglang.launch_server \
    --model Qwen/Qwen2.5-0.5B-Instruct \
    --host 0.0.0.0 \
    --port 8000 \
    --disable-radix \
    --trust-remote-code \
    --device cpu \
    --attention-backend torch_native \
    --log-requests \
    --disable-cuda-graph \
    --disable-cuda-graph-padding \
    --disable-outlines-disk-cache \
    --disable-custom-all-reduce \
    --disable-overlap-schedule \
    --enable-torch-compile \
    --sampling-backend pytorch \
    --torch-compile-max-bs 1024 \
    --max-running-requests 10 \
    --stream-interval 5 \
    --stream-output \
    --log-level debug \
    --enable-mixed-chunk \
    --allow-auto-truncate \
    --deepep-mode auto
```

## 4. build with
```bash
docker build -f docker/Dockerfile.cpu -t sglang-cpu  .
```

## 5. Run SGlang
```bash
docker run -it -p 8000:8000 -v /tmp/.cache:/root/.cache --rm sglang-cpu ./entrypoint.sh 
```
or run with, 
```bash
docker run -it -p 8000:8000 -v /tmp/.cache:/root/.cache --rm sglang-cpu /bin/bash
```
and run inside docker with 
```bash
python -m sglang.launch_server --host 0.0.0.0 --port 8000 --device cpu  --model-path Qwen/Qwen2.5-0.5B-Instruct
```
for embedding add `--is-embedding`

example for complex configuration

```bash
python3 -m sglang.launch_server --model Qwen/Qwen2.5-0.5B-Instruct --host 0.0.0.0 --port 8000 --disable-radix --trust-remote-code --device cpu --attention-backend torch_native --log-requests --disable-cuda-graph   --disable-cuda-graph-padding   --disable-outlines-disk-cache   --disable-custom-all-reduce   --disable-overlap-schedule --enable-torch-compile --sampling-backend pytorch --torch-compile-max-bs 1024 --max-running-requests 10 --stream-interval 5 --stream-output --log-level debug --enable-mixed-chunk --allow-auto-truncate --deepep-mode auto
```
if error downloading, export HF_TOKEN
```bash
export HF_TOKEN=xxx
```

for run VLLM inside docker and cpu mode 

```bash
python3 -m vllm.entrypoints.openai.api_server --trust-remote-code --model  intfloat/multilingual-e5-large-instruct
```

## Note
- this SGlang, didn't support LORA CPU
- sglang not yet support GGUF
