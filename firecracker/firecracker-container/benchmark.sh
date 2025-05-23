#!/bin/bash
set -e


# ================================================
#  Firecracker vs Containerd Benchmark Script
# ================================================
# This script benchmarks firecracker-containerd and containerd using nginx, iperf3, and sysbench.
# It requires firecracker-containerd and containerd to be installed and running.
# Author: GDP Labs
# ================================================

set -e

echo -e "\n🔄 Installing dependencies (iperf3, containerd)..."
apt-get update > /dev/null 2>&1 && apt-get install -y iperf3 containerd > /dev/null 2>&1

echo -e "\n📦 Pulling required images..."
sudo ctr images pull docker.io/library/nginx:latest
sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc images pull docker.io/library/nginx:latest

sudo ctr images pull docker.io/networkstatic/iperf3:latest
sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc images pull docker.io/networkstatic/iperf3:latest

sudo ctr images pull docker.io/library/debian:stable-slim
sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc images pull docker.io/library/debian:stable-slim


sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc container rm cpu-test > /dev/null 2>&1 || true
sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc container rm io-test > /dev/null 2>&1 || true
sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc container rm mem-test > /dev/null 2>&1 || true
sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc container rm net-test > /dev/null 2>&1 || true
sudo ctr container rm cpu-test > /dev/null 2>&1 || true
sudo ctr container rm io-test > /dev/null 2>&1 || true
sudo ctr container rm mem-test > /dev/null 2>&1 || true
sudo ctr container rm net-test > /dev/null 2>&1 || true


echo -e "\n🚀 Benchmark: Startup Time (nginx)"

echo "[containerd]"
time ctr run --rm --tty --net-host docker.io/library/nginx:latest nginx-test-ctr nginx
echo "[firecracker-containerd]"
time firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc run --rm --tty --net-host docker.io/library/nginx:latest nginx-test-fc-ctr nginx

echo -e "\n🚀 Benchmark: CPU Performance (sysbench)"
echo "[containerd]"
ctr run --net-host --rm docker.io/library/debian:stable-slim cpu-test bash -c "apt-get update > /dev/null 2>&1 && apt-get install -y sysbench > /dev/null 2>&1 && sysbench cpu --cpu-max-prime=20000 run"
echo "[firecracker-containerd]"
firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc run --net-host --rm docker.io/library/debian:stable-slim cpu-test bash -c "apt-get update > /dev/null 2>&1 && apt-get install -y sysbench > /dev/null 2>&1 && sysbench cpu --cpu-max-prime=20000 run"

echo -e "\n🚀 Benchmark: IO Performance (sysbench)"
echo "[containerd]"
ctr run --net-host --rm docker.io/library/debian:stable-slim io-test bash -c "apt-get update > /dev/null 2>&1 && apt-get install -y sysbench > /dev/null 2>&1 && mkdir -p /tmp/test && time sysbench fileio --file-total-size=1G --file-test-mode=rndrw --time=30 prepare && sysbench fileio --file-total-size=1G --file-test-mode=rndrw --time=30 run && sysbench fileio cleanup"
echo "[firecracker-containerd]"
firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc run --net-host --rm docker.io/library/debian:stable-slim io-test bash -c "apt-get update > /dev/null 2>&1 && apt-get install -y sysbench > /dev/null 2>&1 && mkdir -p /tmp/test && sysbench fileio --file-total-size=1G --file-test-mode=rndrw --time=30 prepare && sysbench fileio --file-total-size=1G --file-test-mode=rndrw --time=30 run && time sysbench fileio cleanup"

echo -e "\n🚀 Benchmark: Memory Performance (sysbench)"
echo "[containerd]"
ctr run --net-host --rm docker.io/library/debian:stable-slim mem-test bash -c "apt-get update > /dev/null 2>&1 && apt-get install -y sysbench > /dev/null 2>&1 && sysbench memory --memory-block-size=1K --memory-total-size=100m run"
echo "[firecracker-containerd]"
firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc run --net-host --rm docker.io/library/debian:stable-slim mem-test bash -c "apt-get update > /dev/null 2>&1 && apt-get install -y sysbench > /dev/null 2>&1 && sysbench memory --memory-block-size=1K --memory-total-size=100m run"

echo -e "\n🔄 Restarting iperf3 server on host..."
systemctl restart iperf3.service

echo -e "\n🚀 Benchmark: Network Performance (iperf3)"
echo "[containerd]"
ctr run --net-host --rm docker.io/networkstatic/iperf3:latest net-test iperf3 -c localhost -t 30
echo "[firecracker-containerd]"
firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc run --net-host --rm docker.io/networkstatic/iperf3:latest net-test iperf3 -c localhost -t 30

systemctl rm iperf3.service > /dev/null 2>&1

echo -e "\n✅ Benchmark completed! Review the results above."
