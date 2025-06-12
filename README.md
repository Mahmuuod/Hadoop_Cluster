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


# Hive on Tez with Postgres Metastore & BigQuery Migration

This project builds a Docker image for Apache Hive running on Tez, using PostgreSQL as the Hive Metastore, and includes migration support from Google BigQuery to Hive.

## 📦 Project Structure

- `Dockerfile` – Builds the Hive environment with necessary dependencies.
- `postgres-init.sql` – Initializes the PostgreSQL database schema for Hive Metastore.
- `entrypoint.sh` – Custom script to initialize services on container startup.

## 🐳 Docker Image Overview

This Docker image includes:

- Apache Hive
- Apache Tez
- Hadoop (dependencies for Hive and Tez)
- PostgreSQL client
- Google Cloud SDK (for BigQuery data export)

### 🛠 Build the Image

```bash
docker build -t hive-tez-postgres .
```

### ▶️ Run the Container

```bash
docker run -d --name hive-tez \
  -p 10000:10000 \
  -e POSTGRES_HOST=your_postgres_host \
  -e POSTGRES_DB=hive_metastore \
  -e POSTGRES_USER=hive \
  -e POSTGRES_PASSWORD=your_password \
  hive-tez-postgres
```

## 🗃 PostgreSQL Metastore

Ensure you have a PostgreSQL instance with the Hive Metastore schema. You can use the provided `postgres-init.sql` or manually create the database using the Hive schema scripts.

## 🔄 BigQuery to Hive Migration

Use the Google Cloud SDK to export BigQuery data as CSV or Avro to Google Cloud Storage, and then move it to HDFS using `gsutil` or local staging.

### Example Steps:

1. Export BigQuery data to GCS:
   ```bash
   bq extract --destination_format=CSV 'project.dataset.table' gs://your-bucket/data.csv
   ```

2. Copy from GCS to local or HDFS:
   ```bash
   gsutil cp gs://your-bucket/data.csv .
   hdfs dfs -put data.csv /user/hive/warehouse/your_table/
   ```

3. Create and load Hive table:
   ```sql
   CREATE EXTERNAL TABLE your_table (
     col1 STRING,
     col2 INT
   )
   ROW FORMAT DELIMITED
   FIELDS TERMINATED BY ','
   STORED AS TEXTFILE
   LOCATION '/user/hive/warehouse/your_table/';
   ```

# Dockerfile Documentation: Hive on Tez with Postgres Metastore

This Dockerfile sets up an environment to run Apache Hive with Tez as the execution engine and PostgreSQL as the metastore backend. Below is an explanation of each section of the Dockerfile.

---

## 🏗 Base Image

```dockerfile
FROM openjdk:8-jdk
```

- Uses the official OpenJDK 8 image as the base.
- Required for running Hadoop, Hive, and Tez.

---

## 📂 Environment Variables

```dockerfile
ENV HIVE_VERSION=3.1.2
ENV HADOOP_VERSION=3.2.1
```

- Sets specific versions for Hive and Hadoop to ensure compatibility.

---

## 📦 Install Dependencies

```dockerfile
RUN apt-get update && apt-get install -y ...
```

- Updates package lists.
- Installs utilities like `wget`, `curl`, `procps`, `ssh`, `vim`, `net-tools`, `python`, etc.
- Ensures the container has basic tools for debugging and operations.

---

## ⬇️ Download & Install Hadoop

```dockerfile
RUN wget ... && tar -xzf ... && mv ...
```

- Downloads Hadoop from the Apache archive.
- Extracts and installs it to `/opt/`.

---

## ⬇️ Download & Install Hive

```dockerfile
RUN wget ... && tar -xzf ... && mv ...
```

- Downloads Apache Hive.
- Moves it to `/opt/`.

---

## ⬇️ Download & Install Tez

```dockerfile
RUN wget ... && tar -xzf ... && mv ...
```

- Downloads Apache Tez.
- Required as the execution engine for Hive.

---

## 🔧 Configurations

```dockerfile
COPY hive-site.xml ...
COPY tez-site.xml ...
COPY core-site.xml ...
COPY hdfs-site.xml ...
```

- Copies custom configuration files into the appropriate Hive and Hadoop directories.
- These XML files configure Hive Metastore, HDFS, and Tez.

---

## 🧪 PostgreSQL JDBC Driver

```dockerfile
COPY postgresql-<version>.jar ...
```

- Adds the PostgreSQL JDBC driver to Hive's lib folder for Metastore connectivity.

---

## 🚀 Entry Point

```dockerfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

- Copies and sets execute permission on an entrypoint script.
- `entrypoint.sh` initializes Hive services when the container starts.

---

## 📁 Work Directory

```dockerfile
WORKDIR /opt/hive
```

- Sets the default working directory to Hive's root folder.

---

## 📡 Port Exposure

```dockerfile
EXPOSE 10000
```

- Exposes port `10000`, which is the default port for HiveServer2.

---

## 📝 Summary

This Dockerfile creates a ready-to-run environment for Hive on Tez with Postgres metastore, suitable for development or testing of Hadoop ecosystem applications.

# Hive Startup Script Documentation

This script initializes and launches Hive components depending on the hostname of the container. It uses the hostname to determine the role (`meta-store`, `hive`, etc.) and executes the appropriate logic.

---

## 🔧 Script Logic Breakdown

### General Initialization

```bash
set -e
NODE=$(hostname)

cd
echo $NODE
```

- `set -e`: Makes the script exit on any error.
- `NODE=$(hostname)`: Gets the current container's hostname to identify which Hive component to start.
- `cd` and `echo $NODE`: Changes to the home directory and prints the hostname.

---

## 🧠 Role-Based Logic

The script uses a `case` statement to apply different behavior based on the node's role.

### 🗃 Meta-Store Node

```bash
case "$NODE" in
    meta-store*)
```

#### Schema Initialization

```bash
if [ "$NODE" = "meta-store" ]; then
  if PGPASSWORD=hive psql -U hive -h postgres -d metastore -tAc 'SELECT 1 FROM public."VERSION" LIMIT 1;' | grep -q 1; then
    echo "[OK] Hive Metastore schema is already initialized."
  else
    echo "[WARN] Schema not found — initializing Hive schema..."
    /opt/apache-hive-4.0.1-bin/bin/schematool -dbType postgres -initSchema
  fi
```

- Checks if the Hive Metastore schema is initialized in PostgreSQL.
- If not found, it initializes it using `schematool`.

#### Service Startup (on non-meta-store nodes)

```bash
else
  while ! nc -z meta-store 9083 ; do
    echo "Waiting for meta-store"
    sleep 2
  done
  sleep 10
fi
hive --service metastore
```

- Waits for the Metastore to be reachable (port 9083).
- Starts the Hive Metastore service.

---

### 🐝 Hive Server Node

```bash
hive*)
```

#### Wait for HDFS

```bash
while ! nc -z Master1 9870 ; do
  echo "Waiting for Name Node To Be Formatted ..."
  sleep 2
done
sleep 20
```

- Waits until HDFS NameNode on `Master1` is up (port 9870).

#### HDFS Initialization

```bash
hdfs dfs -test -d /app/ || hdfs dfs -mkdir /app/
hdfs dfs -test -e /app/tez.tar.gz || hdfs dfs -put /opt/apache-tez-0.10.4-bin/share/tez.tar.gz /app/
```

- Creates `/app/` directory in HDFS if not exists.
- Uploads Tez archive to HDFS if not already present.

#### Start HiveServer2

```bash
hive --service hiveserver2 &
while ! nc -z localhost 10000 ; do
  echo "wait for hive server to be on"
  sleep 2
done
```

- Starts HiveServer2 in the background.
- Waits until it becomes available on port `10000`.

---

### 🔁 Default Case

```bash
*)
  echo "Unknown node type: $NODE. No specific configuration applied."
  ;;
```

- For any unknown node hostname, prints a message and applies no special configuration.

---

### ✅ Final Log Message and Background Wait

```bash
echo hive server is on 
tail -f /dev/null & wait
```

- Keeps the container alive by tailing `/dev/null`.

---

## 📝 Summary

This script provides a dynamic way to start either the Hive Metastore or HiveServer2 depending on the container role, while also handling initialization and service readiness.

# Hive Data Warehouse DDL Documentation

This document explains the contents of the `ddl.sql` script which is used to define and populate a Hive-based Data Warehouse schema for an airline reservation system.

---

## 🏗️ Database Initialization

```sql
CREATE DATABASE IF NOT EXISTS DWH_Project
...
```

- Creates a Hive database with metadata properties such as creator and purpose.
- Ensures it doesn't overwrite an existing database.

---

## ⚙️ Hive Configuration Settings

```sql
SET hive.exec.dynamic.partition = true;
...
```

- Enables dynamic partitioning and enforces bucketing and sorting for better performance on large datasets.

---

## 📊 Dimension and Fact Tables

The script includes definitions and loading logic for:

### `dim_airport`, `dim_passenger`, `dim_promotions`, etc.
- Represent lookup and descriptive information.
- Use `EXTERNAL TABLE` for flexibility in data location.

### `fact_reservation` (staging and final)
- Collects transactional booking data.
- Final table is `PARTITIONED BY (year)` and `CLUSTERED BY Reservation_Key INTO 16 BUCKETS`.

---

## 🔄 ETL Logic

```sql
INSERT OVERWRITE TABLE fact_reservation PARTITION (year)
...
```

- Loads data from `stage_fact_reservation` into the optimized final table.
- Computes the `year` partition from the `reservation_date_key`.

---

## 🧹 Cleanup

```sql
DROP TABLE stage_fact_reservation;
```

- Removes staging table after loading to keep schema clean.

---
# Hive Transformation Script Documentation

This documentation explains the transformation process executed in `transformation.sql` for preparing data for the Hive Data Warehouse.

---

## 🔁 Transformation Flow

1. **Create `temp_fact_reservation` table**  
   - Aggregates and formats data from multiple normalized operational tables.
   - Handles nulls using `COALESCE`.
   - Extracts date keys as `BIGINT` for efficient partitioning.

2. **Join Logic**
   - Performs `JOIN` operations between:
     - `reservation`
     - `ticket`
     - `seat`
     - `flight`
     - `passenger`
     - `aircraft`
     - `channel`
     - `fare_basis`
     - `promotion` (as `LEFT JOIN` for optional discounts)

---

## 📤 Data Load

```sql
INSERT INTO TABLE dwh_project.fact_reservation PARTITION(year)
...
```

- Loads from `temp_fact_reservation` to the fact table.
- Extracts `year` from `reservation_date_key`.

---

## 🧹 Cleanup

```sql
DROP TABLE temp_fact_reservation;
```

- Removes temporary transformation table post-load.
# PostgreSQL Operational DDL Script Documentation

This file explains the `db_ddl.sql` script which sets up the normalized schema for the airline operational database in PostgreSQL.

---

## 🏗️ Schema Overview

Includes 18 tables for OLTP design:

- Entities: `airport`, `aircraft_model`, `passenger`, `promotion`, `reservation`, etc.
- Uses strong constraints, identity primary keys, and foreign keys.
- Many-to-many relationships managed via join tables (e.g. `flight_crew`).

---

## 🛡️ Constraints & Validations

- Unique constraints (e.g. `airport_code_unique`)
- Enum-like checks (e.g. `status IN (...)`)
- Composite keys where required (e.g. seat uniqueness)

---

## 🔁 Audit Columns

Each table includes:

```sql
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
```

- Tracked by triggers (`trg_*_update_timestamp`) that auto-update `updated_at`.

---

## 🧠 Metadata & Functions

- `meta_data` table tracks the last extraction time.
- `get_last_extraction_time()` retrieves last pull for CDC.
- Incremental views (`vw_*_inc`) reflect only recently modified rows.
# Hive External Views Schema Documentation

This document describes the `db_HQL.sql` file which builds Hive external tables mapped to ORC files generated from PostgreSQL CDC views.

---

## 🗃️ Hive Setup

```sql
DROP DATABASE IF EXISTS airline_views CASCADE;
CREATE DATABASE airline_views;
USE airline_views;
```

- Resets the view layer for Hive-based analytics.

---

## 🧩 Table Mappings

Each table (e.g. `airport`, `passenger`, `reservation`) is:

- Defined as an `EXTERNAL TABLE`
- Points to an ORC file location produced by incremental views
- Allows Hive to query CDC data directly without ingestion

---

## 🔄 Sync Strategy

- Tables reflect the state of `vw_*_inc` views in PostgreSQL.
- External ORC files are assumed to be updated regularly via ETL or Airflow jobs.

---

## 📈 Use Case

Ideal for:

- Hybrid analytics platforms
- Hive, Presto, or SparkSQL-based reporting over near real-time views



## 🧷 Notes

- Netcat (`nc`) is used to ensure critical ports are up before continuing
- The final line `tail -f /dev/null & wait` keeps the container running after services start

---
Maintained by **Data Engineering Enthusiasts**.

## 👤 Author

Created and maintained by **Mahmoud Osama** – Data Engineer | Software Developer | Linux Enthusiast  
Feel free to contribute or suggest improvements via GitHub.


