set -e
HADOOP_HOME="/data/hadoop-3.3.6"
HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
NAMENODE_DIR="/opt/hadoop/name"
JOURNAL_DIR="/opt/hadoop/journal"
ZOOKEEPER_DATA="/opt/zookeeper/data"
ZOOKEEPER_LOG="/opt/zookeeper/log"
NODE=$(hostname)

case "$NODE" in
    "Master1" | "Master2" | "Master3")
        mkdir -p ~/.ssh/
        sudo mkdir -p /opt/hadoop/name
        sudo mkdir -p /opt/hadoop/journal
        sudo mkdir -p /opt/zookeeper/data
        sudo mkdir -p /opt/zookeeper/log
        sudo chown -R hadoop:hadoop /opt/hadoop
        sudo chown -R hadoop:hadoop /opt/zookeeper
        sudo chown -R hadoop:hadoop /data/zookeeper/
        ;;
    "Worker1")
        mkdir .ssh/ 
        ;;
    *)
        echo "Unknown node type: $NODE. No specific configuration applied."
        ;;
esac

case "$NODE" in
    "Master1")
    ssh-keyscan -H master1 worker1 master2 master3 >> ~/.ssh/known_hosts
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@localhost 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@worker1  
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@master2 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@master3 
        ;;
    "Master2")
    ssh-keyscan -H localhost worker1 master1 master3 >> ~/.ssh/known_hosts
	sudo service ssh start 
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@localhost 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@worker1  
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@master1 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@master3 
        ;;
    "Master3")
    ssh-keyscan -H localhost worker1 master1 master2 >> ~/.ssh/known_hosts
	sudo service ssh start 
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@localhost 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@worker1 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@master2 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@master1 

        ;;
    "Worker1")

    ssh-keyscan -H localhost master2 master1 master3 >> ~/.ssh/known_hosts
	sudo service ssh start 
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@master3 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub localhost  
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@master2 
	sshpass -p "123" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub hadoop@master1 
    ;;
    *)
        echo "Unknown node type: $NODE. No specific configuration applied."
        ;;
esac


echo export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64 >> .profile 
echo export HADOOP_CONF_DIR=/data/hadoop-3.3.6/etc/hadoop/ >> .profile
echo export HADOOP_HOME=/data/hadoop-3.3.6 >>.profile
echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:/data/zookeeper/bin/' >> .profile 
echo sudo service ssh start >> .profile 
source ~/.profile

case "$NODE" in
    "Master1" | "Master2" | "Master3")
        echo 'hdfs --daemon start journalnode && hdfs --daemon start namenode && yarn --daemon start resourcemanager && zkServer.sh start && hdfs --daemon start zkfc' >> .profile
        ;;
    "Worker1")
        echo 'hdfs --daemon start datanode && yarn --daemon start nodemanager' >> .profile
        ;;
    *)
        echo "Unknown node type: $NODE. No specific configuration applied."
        ;;
esac


case "$NODE" in
    "Master1" ) 
    hdfs --daemon start journalnode  
    echo 1 > /opt/zookeeper/data/myid 
    zkServer.sh start
        ;;
    "Master2" ) 
    hdfs --daemon start journalnode  
    echo 2 > /opt/zookeeper/data/myid 
    zkServer.sh start
        ;;
    "Master3")
    hdfs --daemon start journalnode  
    echo 3 > /opt/zookeeper/data/myid 
    zkServer.sh start
        ;;
    "Worker1")
        ;;
    *)
        echo "Unknown node type: $NODE. No specific configuration applied."
        ;;
esac

sleep 5

case "$NODE" in
    "Master1" ) 
    hdfs namenode -format  
    hdfs --daemon start namenode  
    hdfs zkfc -formatZK 
    hdfs --daemon start zkfc 
    yarn --daemon start resourcemanager
        ;;
    "Master2" ) 
    sleep 30
    hdfs namenode -bootstrapStandby
    hdfs --daemon start namenode
    yarn --daemon start resourcemanager
    hdfs --daemon start zkfc
        ;;
    "Master3")
    sleep 30
    hdfs namenode -bootstrapStandby
    hdfs --daemon start namenode  
    yarn --daemon start resourcemanager
    hdfs --daemon start zkfc
        ;;
    "Worker1")
    sleep 30
    hdfs --daemon start datanode 
    yarn --daemon start nodemanager
        ;;
    *)
        echo "Unknown node type: $NODE. No specific configuration applied."
        ;;
esac
su - hadoop 