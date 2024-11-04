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
