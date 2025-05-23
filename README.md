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
