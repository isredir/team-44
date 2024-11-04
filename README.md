# Автоматизированное развертывание кластера Hadoop.

Кластер Hadoop предстовляет собой ...

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
   - В личной папке каждого пользователя hadoop_test создаем папку `.ssh`, если такой нет.
3. Теперь нужно выйти на jn и склонировать туда данный репозиторий. Использовать нужно команду `git clone ... hadoop_repo`. Если вы сделали все верно, после этого шага на jn в корне должна появиться папка `hadoop_repo` с двумя подпапками: `jn_setup`, `hadoop_setup`.
4. Теперь нужно запустить настройку jn. Для этого нужно запустить скрипт командой `bash hadoop_repo/jn_setup/jn_setup.sh`. После этой команды у вас должен появиться конфиг `.ssh/config` позволяющий проще подключаться к другим хостам. А также на хост nn должна быть скопирована папка `hadoop_setup`.
5. Подключитесь к хосту `ssh nn`. При необходимости введите пароль. На этом хосте нужно запустить скрипт командой `bash hadoop_setup/hadoop_setup.sh`. В ходе выполнения команды сначала настроятся соединения по ssh без пароля между узлами кластера, а затем скачается, распакуется архив с Hadoop и конфигурации будут дублированы на другие узлы. После всего этого должно произойти форматирование для namenode и подъем кластера. Командой `jps` можно проверить, что на хосте team-44-nn корректно развернуты NameNode, SecondaryNameNode и DataNode.
6. Чтобы иметь доступ к web-интерфейсу, настроим nginx. Для этого нужно выйти на jn. Там от имени суперпользователя нужно проделать следующие операции:
   - `cd /etc/nginx/sites-available` -- переходим в директорию конфигурации nginx.
   - `sudo cp default nn` -- копируем default, чтобы теперь слушать ещё и порт 9870.
   - `sudo vim nn` -- здесь нужно отредактировать файл так, чтобы слушать порт 9870 и перенастроить проксирование на http://192.168.1.179:9870. конфигурация должна будет выглядеть так:
     ```
      server {
      	listen 9870 default_server;
      
      	root /var/www/html;
      
      	index index.html index.htm index.nginx-debian.html;
      
      	server_name _;
      
      	location / {
      		proxy_pass http://192.168.1.179:9870;
      	}
      }
     ```
     После этого надо **выйти из vim**. (Я верю, у вас получится!)
   - `cd ../sites-enabled`
   - `ln -s ../sites-available/nn nn` -- создаем симлинку на созданный файл.
   - `sudo systemctl reload nginx` -- перезагружаем nginx. Если ошибок нет, значит, все заработало.
7. Тут видимо будет что-то про ярн?
