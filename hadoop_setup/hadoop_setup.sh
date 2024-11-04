#!/bin/bash

cd ~
HADOOP_SETUP=~/hadoop_setup

# делаем упражнение с ssh-ключами
cp ~/hadoop_setup/ssh_config ~/.ssh/config
echo '' >> ~/.ssh/authorized_keys 
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

scp -r ~/.ssh dn0:~/
scp -r ~/.ssh dn1:~/

echo "Скачиваем Hadoop..."
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz

echo "Распаковываем Hadoop..."
tar -xzf hadoop-3.4.0.tar.gz

# установка переменных JAVA_HOME и HADOOP_HOME
cd hadoop-3.4.0/
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/hadoop-3.4.0/etc/hadoop/hadoop-env.sh
export HADOOP_HOME=/home/hadoop_test/hadoop-3.4.0
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

echo '' >> ~/.profile
echo 'export HADOOP_HOME=/home/hadoop_test/hadoop-3.4.0' >> ~/.profile
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.profile
echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> ~/.profile

scp ~/.profile dn0:~/
scp ~/.profile dn1:~/

echo "Pause available" -n
echo $1 'sec'
sleep $1
echo "Pause unavailable"

echo "Заполняем конфигурационные файлы..."
# тут должны быть инструкции пользователя по редактированию файлов
# например, пользователю нужно заполнить или заменить следующие строки
cp ~/hadoop_setup/core-site.xml etc/hadoop/core-site.xml  
cp ~/hadoop_setup/hdfs-site.xml etc/hadoop/hdfs-site.xml
cp ~/hadoop_setup/workers etc/hadoop/workers

echo "Создаем необходимые директории для NameNode и DataNode..."
mkdir -p ~/mydata/hdfs/namenode
mkdir -p ~/mydata/hdfs/datanode

echo "Копируем данные hadoop на другие узлы"
scp -q -r ~/hadoop-3.4.0 dn0:~/
scp -q -r ~/hadoop-3.4.0 dn1:~/
scp -q -r ~/mydata dn0:~/
scp -q -r ~/mydata dn1:~/
# echo "Введите хосты (через пробел), на которые следует скопировать hadoop-3.4.0/:"
# read -a hosts
# 
# for host in "${hosts[@]}"
# do
#   echo "Копируем Hadoop на $host..."
#   scp -r ../hadoop-3.4.0 "$host:~/"
# done

echo "Форматируем name-node..."
bin/hdfs namenode -format

echo "Запускаем кластер..."
sbin/start-dfs.sh
# sbin/start-yarn.sh

echo "Hadoop кластер запущен."
