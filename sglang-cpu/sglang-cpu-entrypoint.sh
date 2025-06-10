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
