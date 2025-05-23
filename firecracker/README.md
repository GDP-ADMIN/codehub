
# Firecracker Automation Scripts

This directory contains a collection of shell scripts to automate the setup, configuration, and benchmarking of Firecracker microVMs and Firecracker-containerd environments.

## Table of Contents

- [Dependencies](#dependencies)
- [Script Overview](#script-overview)
- [Usage](#usage)
- [Notes](#notes)

---

## Dependencies


- **OS:** Debian/Ubuntu system
- **Packages:** `curl`, `wget`, `jq`, `git`, `make`, `docker`, `containerd`, `firecracker`, `firecracker-containerd`
- **Privileges:** Some scripts require `sudo` privileges
- **CPU:** Must be **Skylake, Cascade Lake, Ice Lake, Milan, Neoverse V1** or newer
- **Cloud:** On AWS EC2, use only `.metal` instance types (KVM is supported only on these)
- **Kernel Support:**
  - **Host Kernel:**
    | Host kernel | Min. version | Min. end of support |
    | ----------- | ------------ | ------------------- |
    | v5.10       | v1.0.0       | 2024-01-31          |
    | v6.1        | v1.5.0       | 2025-10-12          |
  - **Guest Kernel:**
    | Guest kernel | Min. version | Min. end of support |
    | ------------ | ------------ | ------------------- |
    | v5.10        | v1.0.0       | 2024-01-31          |
    | v6.1         | v1.9.0       | 2026-09-02          |

> **Before you start:**
> - Read the [Firecracker Getting Started Guide](https://github.com/firecracker-microvm/firecracker/blob/main/docs/getting-started.md)

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

This section provides a step-by-step guide to set up, run, and benchmark Firecracker and Firecracker-containerd. Example outputs are included for clarity.

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
0 upgraded, 0 newly installed, 0 to remove and 94 not upgraded.
kvm_intel             380928  0
kvm                  1146880  1 kvm_intel
irqbypass              16384  1 kvm
Access granted.
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

> **Note:** Ensure the downloaded files exist in your current directory before proceeding.

---


### 4. Set Up Networking and Start a MicroVM via API

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

### 5. Create Debian Costum Rom
```bash
sudo ./4th-firecracker-debian-custum-rom.sh
```
_Create Rom with debian based_
 if you need add some package or apps, just edit after line 

 ```# Chroot into the new system and configure it```
 
**Example Output:**
```
Root filesystem image 'debian_bookworm_rootfs.ext4' has been created and configured with Python 3, Node.js, Nano, Vim, Neofetch, and an alias for 'python' pointing to 'python3'.
```

> **Note:** Ensure the file `debian_bookworm_rootfs.ext4` exists in your current directory before starting the custom ROM.

### 5. Start Debian Costum Rom

```bash
sudo ./5th-firecracker-start-debian-cusrom.sh
```
_Starts the custom Debian ROM in a Firecracker microVM._

**Example Output:**
```
Welcome to Debian ...
root@microvm:~#
```
---



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

# Run firecrackers as containerd replacement

---

# Firecracker as a containerd Replacement

> **Before you start:**
> - Read the [Firecracker-containerd Quickstart](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/quickstart.md)
> - Read the [Firecracker-containerd Getting Started](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/getting-started.md)

## Prerequisites

You need to have the following things in order to use firecracker-containerd:

* A computer with a recent-enough version of Linux (4.14+), an Intel x86_64
  processor (AMD and Arm are on the roadmap, but not yet supported), and KVM
  enabled.  An i3.metal running Amazon Linux 2 is a good candidate.

  <details>

  <summary>Click here to see a bash script that will check if your system meets
  the basic requirements to run Firecracker.</summary>

  ```bash
  #!/bin/bash
  err=""; \
  [ "$(uname) $(uname -m)" = "Linux x86_64" ] \
    || err="ERROR: your system is not Linux x86_64."; \
  [ -r /dev/kvm ] && [ -w /dev/kvm ] \
    || err="$err\nERROR: /dev/kvm is inaccessible."; \
  (( $(uname -r | cut -d. -f1)*1000 + $(uname -r | cut -d. -f2) >= 4014 )) \
    || err="$err\nERROR: your kernel version ($(uname -r)) is too old."; \
  dmesg | grep -i "hypervisor detected" \
    && echo "WARNING: you are running in a virtual machine. Firecracker is not well tested under nested virtualization."; \
  [ -z "$err" ] && echo "Your system looks ready for Firecracker!" || echo -e "$err"
  ```

  </details>
* git
* gcc, required by the Firecracker agent for building
* A recent installation of [Docker CE](https://docker.com).
* Go 1.23 or later, which you can download from [here](https://golang.org/dl/).


### 1. Build and Run Firecracker-containerd

#### a) Install Containerd/Dev Tools

```bash
cd firecracker-container
sudo ./1st-fc-ct-deps.sh
```
**Example Output:**
```
Library version:   1.02.185 (2022-05-18)
Driver version:    4.47.0

go version go1.23.4 linux/amd64
```

#### b) Compile Firecracker-containerd

```bash
sudo ./2nd-fc-ct-compile.sh
```
**Example Output:**
```
{
  "firecracker_binary_path": "/usr/local/bin/firecracker",
  "cpu_template": "T2",
  "log_fifo": "fc-logs.fifo",
  "log_levels": ["debug"],
  "metrics_fifo": "fc-metrics.fifo",
  "kernel_args": "console=ttyS0 noapic reboot=k panic=1 pci=off nomodules ro systemd.unified_cgroup_hierarchy=0 systemd.journald.forward_to_console systemd.unit=firecracker.target init=/sbin/overlay-init",
  "default_network_interfaces": [{
    "CNIConfig": {
      "NetworkName": "fcnet",
      "InterfaceName": "veth0"
    }
  }]
}
```
#### c) Start Firecracker-containerd Daemon

```bash
sudo ./3rd-fc-ct-run-daemon.sh
```
**Example Output:**
```
+ mkdir -p /var/lib/firecracker-containerd
+ sudo tee /etc/systemd/system/firecracker-containerd.service
+ sudo firecracker-containerd --config /etc/firecracker-containerd/config.toml
+ sudo systemctl daemon-reload
+ sudo systemctl enable firecracker-containerd
+ sudo systemctl start firecracker-containerd
+ sudo systemctl status firecracker-containerd
* firecracker-containerd.service - Firecracker Containerd Service
     Loaded: loaded (/etc/systemd/system/firecracker-containerd.service; enabled; preset: enabled)
     Active: active (running) since Fri 2025-05-23 10:06:00 WIB; 1h 57min ago
   Main PID: 134726 (firecracker-con)
      Tasks: 8 (limit: 1020)
     Memory: 9.3M
        CPU: 40.314s
     CGroup: /system.slice/firecracker-containerd.service
             `-134726 /usr/local/bin/firecracker-containerd --config /etc/firecracker-containerd/config.toml

May 23 10:06:00 vm-rochmads systemd[1]: Started firecracker-containerd.service - Firecracker Containerd Service.
```
Firecracer-containerd already served into sock **/run/firecracker-containerd/containerd.sock**

---

## Benchmark Performance

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

## Use Case: Firecracker-containerd as a Replacement for containerd


Firecracker-containerd can serve as a secure, lightweight alternative to containerd for running OCI-compatible container images. It leverages microVMs for enhanced isolation, making it ideal for multi-tenant platforms, CI/CD, serverless workloads, and any scenario where VM-level security is desired with container-like speed and resource efficiency.

---

## Example: Running Docker Images with Firecracker-containerd

You can pull and run standard Docker images using `firecracker-ctr` (a containerd-compatible CLI for Firecracker):

```bash
# Pull a Docker image (e.g., Debian)
sudo firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc images pull docker.io/library/debian:stable-slim

# Run a container in the foreground (interactive shell)
firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc run --net-host --rm docker.io/library/debian:stable-slim cpu-test /bin/bash
```

### Running in the Background

To run a container in the background (detached), use the `-d` flag and specify a long-running process:

```bash
firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc run -d --net-host --rm docker.io/library/nginx:alpine webserver nginx -g 'daemon off;'
```

### Docker Compose-like Multi-Container Example

While Firecracker-containerd does not natively support Docker Compose, you can achieve similar results by running multiple containers with custom networking. For example:

```bash
# Start a web server
firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc run -d --net-host --rm docker.io/library/nginx:alpine webserver nginx -g 'daemon off;'

# Start a database
firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc run -d --net-host --rm docker.io/library/mariadb:latest dbserver mysqld

# Start an app container
firecracker-ctr --address /run/firecracker-containerd/containerd.sock -n fc run -d --net-host --rm docker.io/library/python:3.11-slim appserver python app.py
```

You can script these commands or use a shell script to orchestrate multi-container setups, similar to a simple Compose file. For more advanced orchestration, consider integrating with tools like Nomad or Kubernetes with Firecracker support.



> _For more details, see comments in each script. Fill in the example output sections with your actual results for future reference!_

---

## Using Kata container with firecracker [not working [05 2026]]

 facing issue with
```bash
ctr: failed to start shim: start failed: aws.firecracker: unexpected error from CreateVM: rpc error: code = Unknown desc = failed to create VM: failed to start the VM: [PUT /actions][400] createSyncActionBadRequest  &{FaultMessage:Start microvm error: Failed to get CPU template: The current CPU model is not permitted to apply the CPU template.}: exit status 1: unknown
```
and  vsock that cant bind
```
attempt=129 error="temporary vsock dial failure: vsock ack message failure: failed to read \"OK <port>\" within 1s: EOF" runtime=aws.firecracker vmID=f3fec9c3-7a73-42f0-be5b-0ea1d0352594
DEBU[2025-05-22T16:54:10.258152680+07:00]  
```

#### For further documentation See
- https://github.com/kata-containers/kata-containers/blob/main/docs/how-to/how-to-use-kata-containers-with-firecracker.md
---


## Dificulties
- Deprecated devmapper (beacause firecracker relay on this, to achive fast load) its cant be advantage this day 
    - https://github.com/cri-o/cri-o/issues/7002
    - https://github.com/containerd/containerd/issues/6657
- Devmapper show slow performance rather than modern like overlayfs 
    - https://github.com/containerd/containerd/discussions/6625

- Firecracker now focused on security rather than performance starting within miliseconds
    - https://some-natalie.dev/blog/stop-saying-just-use-firecracker/

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
- https://some-natalie.dev/blog/stop-saying-just-use-firecracker/
