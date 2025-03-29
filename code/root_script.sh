set -e


sudo adduser --disabled-password --gecos "" hadoop 
echo "hadoop:123" | sudo chpasswd 
sudo usermod -aG sudo hadoop 
echo "hadoop ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/hadoop
sudo service ssh start 
echo su - hadoop >> ~/.bashrc 
su - hadoop -c "bash /code/hadoop_script.sh"