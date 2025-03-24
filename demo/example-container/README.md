# Example Container Deployment

## Conflicting Dependencies

**Imagine this**: *Your server runs two applications. App X needs Python 3.10 & Debian 11, while App Y requires Python 3.12 and Debian 12. These conflicting dependencies can exist on the same server. That’s where containers come in.*

## Prerequisites

Ensure you have the following are prepared on your system:

- Install [Git](https://git-scm.com/downloads) - for version control and cloning the repository.
- Install [Docker](https://docs.docker.com/engine/install/) - for containerizing and running the application locally.

## Local Installation

> [!NOTE]
>
> - This guide can be simplified to just a few commands. However, to help you better understand how to build and run a container step by step, this documentation provides a more detailed walkthrough.

Follow these steps to simulate the deployment of two applications with conflicting dependencies on your local machine.

### 1. Clone the Repository
Clone this repository to your local machine using Git:
```bash
git clone https://github.com/michaelact/example-container
```

This will create a directory named `example-container` containing the project files.

---

### 2. Navigate to the Application Directory
This repository contains two applications: **App X** and **App Y**. Each application has its own directory with a `Dockerfile`, `docker-compose.yml`, and source code.

To work with **App X**, navigate to its directory:
```bash
cd example-container/appx/
```

To work with **App Y**, navigate to its directory:
```bash
cd example-container/appy/
```

---

### 3. Build the Docker Image
Each application has its own `Dockerfile`, which defines how the application is containerized. To build the Docker image for the application, run:

For **App X**:
```bash
docker build --no-cache -t appx .
```

For **App Y**:
```bash
docker build --no-cache -t appy .
```

**What this does**:
- The `docker build` command reads the `Dockerfile` and creates a Docker image for the application.
- The `-t` flag tags the image with a name (`appx` or `appy`), making it easier to reference later.

---

### 4. Verify the Docker Image
After building the image, you can verify that it was created successfully by listing all Docker images on your system:
```bash
docker images
```

**Expected Output**:
```
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
appx         latest    abcdef123456   10 seconds ago   925MB
appy         latest    789ghi101112   15 seconds ago   925MB
```

---

### 5. Deploy the Application
Each application directory contains a `docker-compose.yml` file, which defines how the container should be run. To start the application, use Docker Compose:

```bash
docker compose up -d
```

**What this does**:
- The `docker compose up` command reads the `docker-compose.yml` file and starts the container.
- The `-d` flag runs the container in detached mode (in the background).

---

### 6. Verify the Application is Running
To check if the application is running, use the following command:
```bash
docker ps
```

**Expected Output**:
```
CONTAINER ID   IMAGE   COMMAND          CREATED         STATUS         PORTS                    NAMES
abcdef123456   appx    "python app.py"  10 seconds ago  Up 9 seconds   0.0.0.0:5000->5000/tcp   appx_container
789ghi101112   appy    "python app.py"  15 seconds ago  Up 14 seconds  0.0.0.0:5001->5001/tcp   appy_container
```

---

### 7. Test the Application
Once the containers are running, you can test the applications by accessing them in your browser or using `curl`:

For **App X** (Python 3.10):
```bash
curl http://localhost:5000
```
**Expected Output**:
```
Hello from App X (Python 3.10)!
```

For **App Y** (Python 3.12):
```bash
curl http://localhost:5001
```
**Expected Output**:
```
Hello from App Y (Python 3.12)!
```

---

### 8. Stop the Application
When you’re done, you can stop the containers using Docker Compose:
```bash
docker compose down
```

**What this does**:
- Stops and removes the containers while preserving the Docker images.
