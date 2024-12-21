cd ~

echo "Скачиваем Spark..."
wget -q "https://dlcdn.apache.org/spark/spark-3.5.3/spark-3.5.3-bin-hadoop3.tgz"

echo "Распаковываем Spark..."
tar -xzf "spark-3.5.3-bin-hadoop3.tgz"

# установка переменных JAVA_HOME и HADOOP_HOME
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/hadoop-3.4.0/etc/hadoop/hadoop-env.sh
export HADOOP_HOME=/home/hadoop_test/hadoop-3.4.0
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

echo '' >> ~/.profile
echo 'export HADOOP_HOME=/home/hadoop_test/hadoop-3.4.0' >> ~/.profile
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.profile
echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> ~/.profile

echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> ~/.profile
echo 'export SPARK_HOME=/home/hadoop_test/spark-3.5.3-bin-hadoop3' >> .profile
echo 'export PATH=$PATH:$SPARK_HOME/bin' >> .profile
echo 'export SPARK_DIST_CLASSPATH=$SPARK_HOME/jars/*:$(hadoop classpath)' >> .profile
