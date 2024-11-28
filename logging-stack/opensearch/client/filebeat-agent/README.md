## Standalone OpenSearch Server Setup

This directory contains the configuration for the Filebeat client. Filebeat is responsible for shipping logs from various sources (currently only **docker containers**) to the Logstash instance on the server.

### Prerequisites

Make sure you have the following installed on your system:

- [Git](https://git-scm.com/downloads)
- [Rancher Desktop](https://rancherdesktop.io/) or [Docker](https://docs.docker.com/engine/install/)
- Copy the `.env.example` file to `.env` and update the values **if needed** (e.g., passwords, versions).

### Quick Start

Run the following simple command:

```bash
git clone -b one-line https://github.com/GDP-ADMIN/gdplabs-exploration
cd logging-stack/opensearch/client/filebeat-agent/
./install.sh
```

> [!IMPORTANT]
>
> - This script are only supported to run in Linux (bash) operating system.
