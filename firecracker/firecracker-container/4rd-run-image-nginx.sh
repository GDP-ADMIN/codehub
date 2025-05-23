#!/bin/bash 
set -ex

sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock \
  -n fc images pull docker.io/library/nginx:latest

sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock \
  -n fc \
  run --rm --tty --net-host \
  docker.io/library/nginx:latest nginx-test


sudo ctr images pull docker.io/library/nginx:latest

sudo ctr run --rm --tty --net-host docker.io/library/nginx:latest nginx-test
