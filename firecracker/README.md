
# Firecracker Automation Scripts

This directory contains a collection of shell scripts to automate the setup, configuration, and benchmarking of Firecracker microVMs and Firecracker-containerd environments.

## Table of Contents

- [Dependencies](#dependencies)
- [Script Overview](#script-overview)
- [Usage](#usage)
- [Notes](#notes)

---

## Dependencies

- Debian/Ubuntu system
- `curl`, `wget`, `jq`, `git`, `make`, `docker`, `containerd`, `firecracker`, `firecracker-containerd`
- Some scripts require `sudo` privileges

---

## Script Overview

### Firecracker Base Scripts

- **0-firecrackers-deps.sh**  
  Installs core dependencies: `squashfs-tools`, `debootstrap`, `acl`. Checks KVM access and adds the user to the `kvm` group if needed.

- **1st-firecracker-download.sh**  
  Downloads the latest Firecracker binary for your architecture and installs it to `/usr/local/bin/`.

- **2nd-firecracker-download-root-kernel.sh**  
  Downloads the latest Firecracker kernel and Ubuntu rootfs, prepares an ext4 image, and sets up SSH keys for VM access.

- **3rd-firecracker-start-micro_vm-via-network.sh**  
  Sets up a TAP network interface, configures NAT, and prepares the Firecracker API socket and logging for microVM networking.

- **3rd-firecracker-start-oneclick.sh**  
  Creates a Firecracker VM configuration JSON and launches a VM with a single command.

- **4th-firecracker-debian-custum-rom.sh**  
  Builds a custom Debian root filesystem image using debootstrap, mounts it, and installs common packages.

- **5th-firecracker-start-debian-cusrom.sh**  
  Sets up networking and logging, then starts a Firecracker VM using the custom Debian image.

### Firecracker Container Scripts

- **firecracker-container/1st-fc-ct-deps.sh**  
  Installs development tools, Docker, and Go. Sets up Docker repositories and installs required packages.

- **firecracker-container/2nd-fc-ct-compile.sh**  
  Clones and builds Firecracker-containerd and its dependencies, downloads a kernel, and configures the environment.

- **firecracker-container/3rd-fc-ct-run-daemon.sh**  
  Starts the Firecracker-containerd daemon and sets up a systemd service for it.

- **firecracker-container/benchmark.sh**  
  Benchmarks Firecracker-containerd vs. standard containerd using nginx, sysbench, and iperf3 for startup, CPU, IO, memory, and network performance.

- **firecracker-container/4rd-run-image-nginx.sh**  
  (Not summarized here, but likely runs an nginx image in a Firecracker container.)

- **firecracker-container/4rd-create-namespace.sh**  
  (Not summarized here, but likely creates a network namespace for Firecracker.)

---

## How To Use (Step-by-Step)

Follow these steps in order to set up and benchmark Firecracker and Firecracker-containerd:

---

### 1. Install Dependencies

```bash
sudo ./0-firecrackers-deps.sh
```
_Installs squashfs-tools, debootstrap, acl, and checks KVM access._

**Example Output:**
```
[...apt output...]
Access granted.
```

---

### 2. Download Firecracker Binary

```bash
sudo ./1st-firecracker-download.sh
```
_Downloads and installs the latest Firecracker binary for your architecture._

**Example Output:**
```
+ ARCH=x86_64
+ release_url=https://github.com/firecracker-microvm/firecracker/releases
+ latest=...
+ curl -L ... | tar -xz
+ mv ... firecracker
+ cp firecracker /usr/local/bin/
```

---

### 3. Download Kernel and Root Filesystem

```bash
sudo ./2nd-firecracker-download-root-kernel.sh
```
_Downloads the latest kernel and Ubuntu rootfs, prepares an ext4 image, and sets up SSH keys._

**Example Output:**
```
Kernel: vmlinux-...
Rootfs: ubuntu-...ext4
SSH Key: ubuntu-....id_rsa
```

---


### 4. Set Up Networking and Start a MicroVM

#### a) Firecracker API (Recommended, less ambiguous)

```bash
sudo ./3rd-firecracker-start-micro_vm-via-api.sh
```
_Sets up TAP networking, NAT, and launches a microVM using the Firecracker API. This script:_
  - Sets up a TAP device and enables IP forwarding
  - Configures NAT for outbound VM traffic
  - Uses Firecracker's API socket to set logging, kernel, rootfs, network, CPU, and memory
  - Starts the microVM and waits for it to boot
  - Sets up guest networking and DNS via SSH
  - SSHs into the microVM for interactive use

**Example Output:**
```
+ sudo ip tuntap add dev tap0 mode tap
+ sudo ip addr add 172.16.0.1/30 dev tap0
+ sudo ip link set dev tap0 up
+ sudo curl -X PUT --unix-socket /tmp/firecracker.socket ...
+ ssh -i ./ubuntu-...id_rsa root@172.16.0.2
Welcome to Ubuntu ...
root@microvm:~#
```

#### b) One-Click VM Start

```bash
sudo ./3rd-firecracker-start-oneclick.sh
```
_Creates a VM config and launches Firecracker with a single command._

**Example Output:**
```
Starting Firecracker VM...
Remember to quit with type reboot in the VM console

Welcome to Ubuntu ...
root@microvm:~#
```

---

### 5. (Optional) Build and Run Firecracker-containerd

#### a) Install Containerd/Dev Tools

```bash
cd firecracker-container
sudo ./1st-fc-ct-deps.sh
```

#### b) Compile Firecracker-containerd

```bash
sudo ./2nd-fc-ct-compile.sh
```

#### c) Start Firecracker-containerd Daemon

```bash
sudo ./3rd-fc-ct-run-daemon.sh
```

---

### 6. Benchmark Performance

```bash
sudo ./benchmark.sh
```
_Runs startup, CPU, IO, memory, and network benchmarks for both containerd and firecracker-containerd._

**Example Output:**
```
🚀 Benchmark: Startup Time (nginx)
[containerd]
...
[firecracker-containerd]
...
✅ Benchmark completed! Review the results above.
```

---

> _For more details, see comments in each script. Fill in the example output sections with your actual results for future reference!_

---

## Notes

---

## Benchmark Results (May 2025)

The following summarizes the results of running `benchmark.sh` to compare standard containerd and firecracker-containerd performance:

| Test                | containerd                | firecracker-containerd      |
|---------------------|--------------------------|----------------------------|
| **Startup Time**    | 0.50s                    | 0.69s                      |
| **CPU (sysbench)**  | 183.93 events/sec        | 182.34 events/sec          |
| **IO Write Speed**  | 235.32 MiB/s             | 81.37 MiB/s                |
| **IO Read/Write**   | 13.12/8.75 MiB/s         | 4.17/2.78 MiB/s            |
| **Memory Write**    | 1474.97 MiB/s            | 1508.12 MiB/s              |
| **Network (iperf3)**| 12.6 Gbits/sec           | 13.0 Gbits/sec             |

**Observations:**
- **Startup:** Firecracker-containerd has a slightly slower startup time than containerd.
- **CPU:** Both runtimes deliver nearly identical CPU performance.
- **IO:** Firecracker-containerd shows significantly lower disk IO throughput compared to containerd.
- **Memory:** Memory write speeds are similar, with firecracker-containerd slightly ahead.
- **Network:** Firecracker-containerd achieves marginally higher network throughput.

---
- Review each script before running to ensure it matches your environment and security requirements.
- Some scripts require root privileges.
- For detailed steps and troubleshooting, see comments within each script.

---

## References & Further Reading

- https://github.com/firecracker-microvm/firecracker-demo
- https://dev.to/librehash/deploying-firecracker-vms-1d99
- https://medium.com/@kuldeepranjan39/setting-up-firecracker-cdb484bbc78c
- https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/quickstart.md
- https://qiita.com/kizitorashiro/items/7c6df873ec845064b850
- https://tutorialsdojo.com/lets-learn-firecracker-microvm-with-go-firecracker-sdk/
- https://aws.amazon.com/blogs/aws/firecracker-lightweight-virtualization-for-serverless-computing/
- https://computingpost.medium.com/install-firecracker-and-run-microvms-on-opennebula-e48c1c5f6b8n
- https://github.com/firecracker-microvm/firecracker-containerd/issues/472
- https://jvns.ca/blog/2021/01/23/firecracker--start-a-vm-in-less-than-a-second/
- https://some-natalie.dev/blog/stop-saying-just-use-firecracker/
- https://github.com/firecracker-microvm/firecracker/discussions/3061
- https://parandrus.dev/devicemapper/
- https://jvns.ca/blog/2021/01/27/day-47--using-device-mapper-to-manage-firecracker-images/
- https://blog.oddbit.com/post/2018-01-25-fun-with-devicemapper-snapshot/
