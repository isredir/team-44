# создаем конфиг, чтобы потом было удобнее подключаться к другим узлам
cp ssh-config ~/.ssh/config

# генерируем ssh-ключ, который потом распространим на другие узлы и добавляем его в authorized_keys
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ''
echo '' >> ~/.ssh/authorized_keys
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# копируем на нейм-ноду. Потом с неё перекопируем на остальные в другом скрипте
scp ~/.ssh/id_rsa.pub nn:~/.ssh/id_rsa.pub
scp ~/.ssh/id_rsa nn:~/.ssh/id_rsa

# копируем данные для развертывания хадупа на nn
scp -r ~/hadoop_repo/hadoop_setup nn:~/hadoop_setup
