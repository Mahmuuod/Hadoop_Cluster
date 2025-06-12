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
---
## Docker Compose

## 📂 Required Files

Ensure these are present in your build context:

- `./data/configs/hadoop/*`: Hadoop XML configuration files
- `./data/configs/zoo.cfg`: Zookeeper configuration
- `./code/hadoop_script.sh`: Initialization script
This `docker-compose.yml` defines a high-availability Hadoop cluster with **3 Master nodes**, **1 Worker node**, **Zookeeper support**, **Hive metastore**, and a **PostgreSQL database** as the Hive metastore backend. Each component is isolated in its own container, all communicating over a dedicated Docker bridge network.

---

## 📦 Services Overview

- **Master1, Master2, Master3**: Hadoop NameNodes with UI ports exposed and Zookeeper journaling
- **Worker1**: Hadoop DataNode
- **Postgres**: Metastore database for Hive
- **meta-store, meta-store2**: Hive Metastore services
- **hive-server**: HiveServer2 service for executing queries

---

## 🔧 Deployment Features

- **Resource Constraints**: Each service defines CPU and memory limits/reservations.
- **Healthchecks**: Ensures services only start if their dependencies are healthy.
- **Volumes**: Persistent storage for journals, namenodes, datanodes, Zookeeper, and PostgreSQL data.
- **Networking**: All services communicate through the `hadoop_cluster` bridge network.

---

## 🚀 How to Use

1. **Build the image if needed** (for meta-store, hive-server):
    ```bash
    docker-compose build
    ```

2. **Start the cluster**:
    ```bash
    docker-compose up -d
    ```

3. **Check health and logs**:
    ```bash
    docker ps
    docker logs <container_name>
    ```

4. **Access Web UIs**:
    - Hadoop NameNode UI (Master1): `http://localhost:8004`
    - YARN ResourceManager UI (Master1): `http://localhost:8003`
    - HiveServer2 (JDBC): `jdbc:hive2://localhost:10000`
    - Hive Metastore: Ports `9083` and `9084` for HA setup

---

## 📂 Volumes and Storage

- `jn1`, `jn2`, `jn3`: Hadoop JournalNode directories
- `nn1`, `nn2`, `nn3`: NameNode storage
- `zk1`, `zk2`, `zk3`: Zookeeper data
- `sn1`: DataNode storage
- `postgres_data`: PostgreSQL persistence

---

## ⚠️ Notes

- `depends_on` with `condition: service_healthy` requires Docker Compose v3.4+ and Docker Engine 1.29+
- Ensure your custom Hadoop image `hadoop-image:01` is built and available locally
- Adjust exposed ports if running on a shared host
- Add Dockerfiles and configuration for Hive, Hadoop, and Metastore inside the context directory

---
## Configurations
---

## 1. `core-site.xml`

Defines the Hadoop core settings:

- `fs.defaultFS`: HDFS URI (e.g., `hdfs://mycluster`)
- Zookeeper quorum for HA: `dfs.ha.zookeeper.quorum`, `ha.zookeeper.quorum`
- Proxy user permissions: `hadoop.proxyuser.hadoop.hosts`, `hadoop.proxyuser.hadoop.groups`
- Google Cloud Storage integration:
  - `fs.gs.impl` and `fs.AbstractFileSystem.gs.impl`
  - Service account key: `google.cloud.auth.service.account.json.keyfile`

---

## 2. `hdfs-site.xml`

Configures HDFS and HA for NameNodes:

- `dfs.nameservices`: Cluster ID (e.g., `mycluster`)
- `dfs.ha.namenodes.mycluster`: HA node IDs (e.g., `nn1,nn2,nn3`)
- RPC and HTTP addresses for each NameNode (`Master1`, `Master2`, `Master3`)
- JournalNode shared edits and directories
- HA failover and fencing method (`shell(/bin/true)`)
- DataNode settings and replication factor

---

## 3. `mapred-site.xml`

Configures the MapReduce framework:

- Uses `yarn` as execution framework
- Sets `HADOOP_MAPRED_HOME` for AM, Map, and Reduce environments

---

## 4. `yarn-site.xml`

Enables HA for YARN ResourceManager:

- `yarn.resourcemanager.ha.enabled`: Enabled
- `yarn.resourcemanager.cluster-id`: e.g., `cluster1`
- Defines `rm1`, `rm2`, `rm3` with hostnames and UI ports
- Points to Zookeeper quorum
- Enables `mapreduce_shuffle` service on NodeManager

---

## 5. `hadoop-env.sh`

Sets environment variables:

```bash
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export HADOOP_OS_TYPE=${HADOOP_OS_TYPE:-$(uname -s)}
```
---

## 6. `zoo.cfg` (Zookeeper Configuration)

Essential for enabling HA in Hadoop and YARN:

- `tickTime=2000`: Time unit in milliseconds used by Zookeeper
- `dataDir=/opt/zookeeper/data`: Directory where Zookeeper stores in-memory data snapshots
- `clientPort=2181`: Port where the server listens for client connections
- `initLimit=5`: Time the leader waits for followers during startup
- `syncLimit=2`: Time for followers to sync with the leader
- Server list:
  - `server.1=Master1:2888:3888`
  - `server.2=Master2:2888:3888`
  - `server.3=Master3:2888:3888`

These servers enable quorum-based leader election for HA coordination across Hadoop NameNodes and YARN ResourceManagers.
---

# 🚀 Hadoop Bootstrap Script (`hadoop_script.sh`)

This script initializes and starts Hadoop, YARN, HBase, and Zookeeper services inside a Docker container. It handles first-time cluster formatting as well as regular service startup based on the node type, inferred from the hostname.

---

## 🧠 Logic Overview

- Starts SSH service
- Extracts the node hostname and ID using `hostname` and regex
- Checks if HDFS has been previously formatted (`/opt/hadoop/name/current`)
- If not, performs **first-time cluster setup**
- If already formatted, performs **regular service startup**

---

## ⚙️ Behavior by Node Type

### 🟩 `master*`
- Starts JournalNode
- If `NodeID == 1` (Master1):
  - Formats `namenode` and `zkfc`
  - Starts NameNode, ZKFC, ResourceManager
- If `NodeID != 1` (Master2, Master3):
  - Waits for Master1 services to be ready
  - Bootstraps Standby NameNode
  - Starts NameNode, ZKFC, ResourceManager

### 🟨 `worker*`
- Starts `datanode`, `nodemanager`, and HBase `regionserver`

### 🟦 `zk*`
- Sets Zookeeper `myid`
- Starts `zkServer.sh`

### 🟥 `hmaster*`
- Creates `/hbase` directory in HDFS and starts HBase Master

### 🟫 Unknown
- Logs that no matching role was applied

---

## 🔁 Re-Start Behavior (if already formatted)

Each node restarts only the relevant daemons:
- `master*`: JournalNode, NameNode, ZKFC, ResourceManager
- `worker*`: DataNode, NodeManager, RegionServer
- `zk*`: Zookeeper
- `hmaster*`: HBase Master

---



