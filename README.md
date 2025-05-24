# Highly Available Hadoop Cluster with Docker

## Overview

This project demonstrates how to build a **Highly Available Hadoop Cluster** using Docker containers. The cluster includes:

- 3 Master nodes running:
  - Zookeeper
  - HDFS NameNode (active/standby setup)
  - HDFS JournalNode
  - YARN ResourceManager (active/standby setup)

- 1 Worker node running:
  - HDFS DataNode
  - YARN NodeManager

The cluster supports automatic failover for HDFS and YARN services, and can be horizontally scaled by adding more worker nodes.

---

## Project Structure

### Part 1: Manual Setup of Hadoop Cluster

- Setup 4 Ubuntu containers in the same Docker network (Ubuntu 22.04 recommended).
- Manually install and configure all required services:
  - Hadoop 3.3.6
  - Zookeeper ensemble
- Configure HDFS High Availability with Quorum Journal Manager.
- Verify:
  - HDFS and YARN web UIs on all master nodes.
  - Failover by stopping active NameNode and ResourceManager.
  - Data ingestion and MapReduce job execution.
  - Adding additional worker node and verifying in cluster UIs.

### Part 2: Docker Automation

- Containerize the manual setup into a single Docker image supporting both master and worker roles.
- Create a Dockerfile with:
  - Clear build steps
  - Versioned package installs
  - Optimized layer usage
  - All services start from one Dockerfile and managed via entrypoint or CMD scripts.
- Develop a Docker Compose file defining:
  - 3 master services and 1 worker service
  - Network, volume mounts, and health checks
  - Proper hostname and container naming conventions
  - Environment variables (build-time in Dockerfile, runtime in Compose)
  - Ports mapping without conflicts
  - Resource limitations and service dependencies
- The cluster should start fully with no manual post-deployment configuration.

---




## How to Use

### Build Docker Image

```bash
docker build -t hadoop-ha-cluster:latest .

# 🐳 Hadoop + Zookeeper Cluster Docker Image (Ubuntu 22.04)

This Dockerfile sets up a containerized environment for running a Hadoop 3.3.6 cluster with Zookeeper 3.8.4 on **Ubuntu 22.04**, using **OpenJDK 8**. It includes a configured non-root `hadoop` user with passwordless `sudo` access, SSH setup for pseudo-distributed mode, and preloaded configuration files.

## 🛠 Features

- ✔️ Ubuntu 22.04 base image
- ✔️ Hadoop 3.3.6 installation
- ✔️ Zookeeper 3.8.4 installation
- ✔️ OpenJDK 8 for Hadoop compatibility
- ✔️ SSH setup for inter-node communication
- ✔️ Preconfigured Hadoop and Zookeeper directories
- ✔️ Custom bootstrap script support

## 🧱 Image Structure

### ✅ Base Layer

```dockerfile
FROM ubuntu:22.04
```

Installs all required dependencies:

```dockerfile
RUN apt update -y && \
    apt upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    net-tools netcat ssh sshpass openjdk-8-jdk sudo vim wget tar
```

### ✅ Hadoop Setup

```dockerfile
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
```

Extracts Hadoop into `/opt` and removes archive:

```dockerfile
tar -xzf hadoop-3.3.6.tar.gz -C /opt && rm hadoop-3.3.6.tar.gz
```

### ✅ Zookeeper Setup

```dockerfile
wget https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz
```

Extracts to `/opt/zookeeper/zookeeper`:

```dockerfile
tar -xzf apache-zookeeper-3.8.4-bin.tar.gz -C /opt/zookeeper && \
mv /opt/zookeeper/apache-zookeeper-3.8.4-bin /opt/zookeeper/zookeeper && \
rm apache-zookeeper-3.8.4-bin.tar.gz
```

### ✅ Hadoop User Setup

```dockerfile
adduser --disabled-password --gecos "" hadoop && \
echo "hadoop:123" | chpasswd && \
usermod -aG sudo hadoop && \
echo "hadoop ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/hadoop
```

### ✅ SSH Setup

```dockerfile
RUN mkdir -p ~/.ssh && \
    ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
```

### ✅ Directory Structure

Creates required directories:

```bash
/opt/hadoop/name
/opt/hadoop/journal
/opt/hadoop/data
/opt/zookeeper/data
/opt/zookeeper/log
```

And adjusts permissions:

```dockerfile
chown -R hadoop:hadoop /opt/hadoop /opt/zookeeper /opt/hadoop-3.3.6
```

### ✅ Copy Configuration and Scripts

```dockerfile
COPY --chown=hadoop:hadoop --chmod=755 ./data/configs/hadoop/* /opt/hadoop-3.3.6/etc/hadoop/
COPY --chown=hadoop:hadoop --chmod=755 ./data/configs/zoo.cfg /opt/zookeeper/zookeeper/conf/
COPY --chown=hadoop:hadoop --chmod=755 ./code/hadoop_script.sh /home/hadoop/code/
```

### ✅ Environment Variables

```dockerfile
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
ENV HADOOP_HOME=/opt/hadoop-3.3.6
ENV HADOOP_CONF_DIR=/opt/hadoop-3.3.6/etc/hadoop
ENV ZOOKEEPER_HOME=/opt/zookeeper/zookeeper
ENV PATH=$PATH:/opt/hadoop-3.3.6/bin:/opt/hadoop-3.3.6/sbin:/opt/zookeeper/zookeeper/bin
```

### ✅ Entrypoint

```dockerfile
ENTRYPOINT ["/bin/bash", "-c", "/home/hadoop/code/hadoop_script.sh"]
```

## 🚀 Build and Run

To build and run the image:

```bash
docker build -t hadoop-cluster .
docker run -it --rm hadoop-cluster
```

## 📂 Required Files

Ensure these are present in your build context:

- `./data/configs/hadoop/*`: Hadoop XML configuration files
- `./data/configs/zoo.cfg`: Zookeeper configuration
- `./code/hadoop_script.sh`: Initialization script

## 💡 Suggested Improvements

- Use Docker Compose for multi-container orchestration
- Externalize credentials to environment variables
- Implement health checks and logging
- Use build arguments for versioning flexibility
- Consider Alpine base image for reduced size

Maintained by **Data Engineering Enthusiasts**.

## 👤 Author

Created and maintained by **Mahmoud Osama** – Data Engineer | Software Developer | Linux Enthusiast  
Feel free to contribute or suggest improvements via GitHub.


