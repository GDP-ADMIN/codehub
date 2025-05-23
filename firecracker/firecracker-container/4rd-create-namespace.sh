#!/bin/bash 
set -ex

sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock \
  namespaces create fc


sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock \
  namespaces label fc \
  containerd.io/defaults/runtime=aws.firecracker \
  containerd.io/defaults/snapshotter=devmapper

sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock \
  -n fc images pull docker.io/library/busybox:latest

sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock \
  -n fc \
  run --rm --tty --net-host \
  docker.io/library/busybox:latest busybox-test
