# Автоматизированное развертывание кластера Hadoop.

Участники команды:
- Сизов Михаил
- Герман Илья
- Абизм Иван
- Королев Алексей

Чтобы развернуть кластер на трех узлах, нужно выполнить следующую инструкцию:
1. Подключаемся по ssh к jn.
2. Из jn подключаемся по ssh поочередно к адресам хостов nn, dn-00, dn-01. При подключении будет запрошен пароль от пользователя team.
   - На каждом хосте нужно отредактировать файл `/etc/hosts`. Для этого могут понадобиться права суперпользователя. Его содержимое должно быть таким:
     ```
     192.168.1.179 team-44-nn
     192.168.1.180 team-44-dn-00
     192.168.1.181 team-44-dn-01
     ```
   - На каждом хосте создаем пользователя hadoop_test командой `sudo adduser hadoop_test`. Пользователю обязательно нужно задать надежный пароль. Данные пользователя (например, фио и почту) можно оставить пустыми.
   - На каждом хосте переключаемся на созданного пользователя командой `sudo -i -u hadoop_test`. В личной папке создаем папку `.ssh`, если такой нет.
3. Теперь нужно выйти на jn и склонировать туда данный репозиторий. Использовать нужно команду `git clone ... hadoop_repo`. Если вы сделали все верно, после этого шага на jn в корне должна появиться папка `hadoop_repo` с двумя подпапками: `jn_setup`, `hadoop_setup`.
4. Теперь нужно запустить настройку jn. Для этого нужно запустить скрипт командой `bash hadoop_repo/jn_setup/jn_setup.sh`. После этой команды у вас должен появиться конфиг `.ssh/config` позволяющий проще подключаться к другим хостам. А также на хост nn должна быть скопирована папка `hadoop_setup`.
5. Подключитесь к хосту `ssh nn`. При необходимости введите пароль. На этом хосте нужно запустить скрипт командой `bash hadoop_setup/hadoop_setup.sh`. В ходе выполнения команды сначала настроятся соединения по ssh без пароля между узлами кластера, а затем скачается, распакуется архив с Hadoop и конфигурации будут дублированы на другие узлы. После всего этого должно произойти форматирование для namenode и подъем кластера. Вместе с этим будет развернут YARN и History Server. Командой `jps` можно проверить, что на хосте team-44-nn корректно развернуты NameNode, SecondaryNameNode, DataNode, NodeManager, ResourceManager, JobHistoryServer.
6. Чтобы иметь доступ к web-интерфейсу, настроим nginx. Для этого нужно выйти на jn.
   
   Для начала настроим http-авторизацию:
   ```
   # Устанавливаем инструмент для авторизации
   sudo apt-get install apache2-utils
   sudo mkdir -p /etc/apache2
   # Вместо <username> указываем имя пользователя, под которым хотим входить на веб-сервисы, затем придумываем и вводим пароль
   sudo htpasswd -c /etc/apache2/.htpasswd <username>
   ```
   
   Теперь заполняем файлы для веб-сервисов
   ```
   sudo copy /etc/nginx/sites-available/default /etc/nginx/sites-available/nn
   sudo vim /etc/nginx/sites-available/nn
   ```
   Редактируем файл следующим образом:
   
   `listen 80 default_server;` заменяем на `listen 9870 default_server;`
   
   `listen [::]:80 default_server;` комментируем (`# listen [::]:80 default_server;`)
   
   В блоке `location / { ... }`:
      - Добавляем строки:
        ```
        proxy_pass http://192.168.1.179:9870;
        auth_basic "Web interface";
        auth_basic_user_file /etc/apache2/.htpasswd;
        ```
      - Комментируем строку `try_files $uri $uri/ =404;`
   
   После этого надо **выйти из vim**. (Я верю, у вас получится!)
   
   Заполним файл для YARN:
   ```
   sudo copy /etc/nginx/sites-available/nn /etc/nginx/sites-available/ya
   sudo vim /etc/nginx/sites-available/ya
   ```
   Редактируем файл следующим образом:
   
   `listen 9870 default_server;` заменяем на `listen 8088 default_server;`
   
   В блоке `location / { ... }` заменяем `http://192.168.1.179:9870;` на `http://192.168.1.179:8088;`

   Заполним файл для History Server:
   ```
   sudo copy /etc/nginx/sites-available/nn /etc/nginx/sites-available/hs
   sudo vim /etc/nginx/sites-available/hs
   ```
   Редактируем файл следующим образом:
   
   `listen 9870 default_server;` заменяем на `listen 19888 default_server;`
   
   В блоке `location / { ... }` заменяем `http://192.168.1.179:9870;` на `http://192.168.1.179:19888;`
   
   Создаем символические ссылки на созданные файлы
   ```
   ln -s /etc/nginx/sites-available/nn /etc/nginx/sites-enabled/nn
   ln -s /etc/nginx/sites-available/ya /etc/nginx/sites-enabled/ya
   ln -s /etc/nginx/sites-available/hs /etc/nginx/sites-enabled/hs
   ```
   Перезагружаем nginx. Если ошибок нет, значит, все заработало.
   
   `sudo systemctl reload nginx`

   Теперь на 9870 порту можно зайти на веб-интерфейс хадупа
   ![image](https://github.com/user-attachments/assets/87d290f1-32ca-44b6-af40-24ef38af5d5b)
   
   На 8088 порту можно зайти на веб-интерфейс Ярна
   ![image](https://github.com/user-attachments/assets/3d54bb78-2054-4f35-8145-1e6d96dd19d6)

   И на 19888 порту можно зайти на History Server
   ![image](https://github.com/user-attachments/assets/774a25d1-e222-4186-9024-221971f8cc69)


# Развертывание Hive.
1. Настройка конфигурации:
   
   Находясь на jump-node создадим пользователя `hadoop_test`, если его еще нет, и перейдя на него установим hive
   
   ```
   sudo adduser hadoop_test
   sudo -i -u hadoop_test bash
   wget -q "https://dlcdn.apache.org/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz"
   tar -xzf "apache-hive-4.0.1-bin.tar.gz"
   cd apache-hive-4.0.1-bin/lib/
   wget -q https://jdbc.postgresql.org/download/postgresql-42.7.4.jar
   ```
   
   Снова переходим на jump-node и переносим файл с конфигурацией
   
   ```
   sudo cp hive_setup/hive-site.xml /home/hadoop_test/apache-hive-4.0.1-bin/conf/
   sudo chown -R hadoop_test:hadoop_test /home/hadoop_test/apache-hive-4.0.1-bin/conf/
   ```
   
   Также перенесем хадуп на нового пользователя:
   
   ```
   ssh nn
   scp -r hadoop-3.4.0 hadoop_test@<jumpnode-ip>:~/
   ```
   
   И возвращаемся на jump-node
   
3. Установка postgres
   
   Переключаемся на адрес хоста name-node и проводим подготовительные работы
   
   ```
   sudo apt install postgresql
   sudo -i -u postgres
   psql
   CREATE DATABASE metastore;
   CREATE USER hive with password 'YourPassword';
   GRANT ALL PRIVILEGES ON DATABASE "metastore" TO hive;
   ```
   
   Выходим из юзера psql и из юзера postgres, и уже на name-node редактируем конфигурационные файлы
   
   ```sudo vim /etc/postgresql/16/main/postgresql.conf```
   
   Раскомментируем строчку listen_addresses = 'localhost' и вместо 'localhost' пишем '<name-node-ip>' (в кавычках)

   Редактируем еще один файл
   
   ```sudo vim /etc/postgresql/16/main/pg_hba.conf```
   
   В блоке IPv4 local connections добавляем следующую строчку
   
   ```host    metastore       hive            <jumpnode-ip>/32         password```
   
   И удаляем или комментируем эту:
   
   ```host    all             all             127.0.0.1/32            scram-sha-256```
   
   Наконец, перезапускаем постгрес
   
   ```sudo systemctl restart postgresql```
   
5. Запуск hive

   Переходим с jump-node в пользователя hadoop_test и собираем окружение
   
   ```
   sudo -i -u hadoop_test bash
   cd /apache-hive-4.0.1-bin/
   export HADOOP_HOME=/home/hadoop_test/hadoop-3.4.0
   export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
   export HIVE_HOME=/home/hadoop_test/apache-hive-4.0.1-bin
   export HIVE_CONF_DIR=/home/hadoop_test/apache-hive-4.0.1-bin/conf
   export HIVE_AUX_JARS_PATH=/home/hadoop_test/apache-hive-4.0.1-bin/lib/*
   export HIVE_POSTGRES_PASSWORD='YourPassword'
   export PATH=$PATH:$HIVE_HOME/bin
   ```
   
   Поднимаем hive
   
   ```
   bin/hdfs dfs -mkdir -p /user/hive/warehouse
   bin/hdfs dfs -chmod g+w /tmp
   bin/hdfs dfs -chmod g+w /user/hive/warehouse
   bin/schematool -dbType postgres -initSchema
   hive --hiveconf hive.server2.enable.doAs=false --hiveconf hive.security.authorization.enabled=false --service hiveserver2 1>> /tmp/hs2.log 2>> /tmp/hs2.log &
   ```
   
   Командой `jps` можно проверить, что работает `RunJar`.
   
7. Создание базы данных в hive

   Переходим в консоль hive
   
   ```beeline -u jdbc:hive2://<jumpnode-ip>:5433```
   
   В консоли билайна выполняем команды для создания БД
   
   ```
   CREATE DATABASE test;
   DESCRIBE DATABASE test; # для проверки
   ```
   
   Теперь можно посмотреть на базу данных в веб-интерфейсе хадупа в меню Utilities -> Browse the file system
   
   ![image](https://github.com/user-attachments/assets/3b616250-77f7-42cf-9a0c-73c7c601197c)
   
   Теперь если мы перейдем в user -> hive -> warehouse, то мы увидим нашу базу данных
   
   ![image](https://github.com/user-attachments/assets/fe8c4aa9-5abc-4682-89db-d3c575b35196)
   
9. Загрузка таблицы в hive

   Возьмем большую csv таблицу, например customers-100000.csv с сайта https://www.datablist.com/learn/csv/download-sample-csv-files и перенесем ее на jump-node. Затем скопируем ее для пользователя hadoop_test

   ```
   sudo cp customers-100000.csv /home/hadoop_test/
   sudo chown -R hadoop_test:hadoop_test /home/hadoop_test/customers-100000.csv
   ```
   
   Теперь добавим ее в базу данных hive

   ```
   sudo -i -u hadoop_test bash
   hdfs dfs -mkdir /input
   hdfs dfs -chmod g+w /input
   hdfs dfs -put ~/customers-100000.csv /input
   beeline -u jdbc:hive2://<jumpnode-ip>:5433
   use test;
   CREATE TABLE IF NOT EXISTS test.customers (
       `Index` int,
       `Customer Id` string,
       `First Name` string,
       `Last Name` string,
       `Company` string,
       `City` string,
       `Country` string,
       `Phone 1` string,
       `Phone 2` string,
       `Email` string,
       `Subscription Date` timestamp,
       `Website` string)
       PARTITIONED BY (`Partition` string)
       ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
   LOAD DATA INPATH '/input/customers-100000.csv' INTO TABLE test.customers;
   ```

   Таким образом мы получили партиционированную таблицу customers в базе данных test.
