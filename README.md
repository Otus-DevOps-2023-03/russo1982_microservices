# russo1982_microservices


## ДЗ №16 Технология контейнеризации. Введение в Docker
---

**ПЛАН**
- Создание **docker host**
- Создание своего образа
- Работа с **Docker Hub**

Создаю новую ветку **docker-2**, но настроить интеграцию с **travis-ci** не получиться, потому что САНКЦИИ

В новой ветке создаю директорию **dockermonolith**
Далее проверю устнаовен ли:
```bash
$ docker -v
Docker version 24.0.2, build cb74dfc
```
```bash
$ docker compose version
Docker Compose version v2.18.1
```
Для установки **docker-machine** сначала надо ознакомиться с этой статьей [https://docs.docker.com.zh.xy2401.com/v17.12/machine/overview/#why-should-i-use-it]
```bash
Docker Engine runs natively on Linux systems. If you have a Linux box as your primary system, and want to run docker commands, all you need to do is download and install Docker Engine. However, if you want an efficient way to provision multiple Docker hosts on a network, in the cloud or even locally, you need Docker Machine.

Whether your primary system is Mac, Windows, or Linux, you can install Docker Machine on it and use docker-machine commands to provision and manage large numbers of Docker hosts. It automatically creates hosts, installs Docker Engine on them, then configures the docker clients. Each managed host (“machine”) is the combination of a Docker host and a configured client.
```
После через эту статью [https://docs.docker.com.zh.xy2401.com/v17.12/machine/install-machine/#install-machine-directly] устанавливаю **docker-machine**

**Download the Docker Machine binary and extract it to your PATH.**
```bash
$ curl -L https://github.com/docker/machine/releases/download/v0.14.0/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine && \
sudo install /tmp/docker-machine /usr/local/bin/docker-machine
```
**Check the installation by displaying the Machine version:**
```bash
$ docker-machine version
docker-machine version 0.14.0, build 89b8332
```
**Install bash completion scripts**
- Confirm the version and save scripts to **/etc/bash_completion.d**
```bash
$ cd /etc/bash_completion.d/
$ scripts=( docker-machine-prompt.bash docker-machine-wrapper.bash docker-machine.bash ); for i in "${scripts[@]}"; do sudo wget https://raw.githubusercontent.com/docker/machine/v0.14.0/contrib/completion/bash/${i} -P /etc/bash_completion.d; done
```
```bash
$ ls -la
total 48
drwxr-xr-x   2 root root  4096 июн 27 20:23 .
drwxr-xr-x 136 root root 12288 июн 26 20:44 ..
-rw-r--r--   1 root root  6636 ноя 12  2019 apport_completion
-rw-r--r--   1 root root 12205 июн 27 20:23 docker-machine.bash
-rw-r--r--   1 root root  1469 июн 27 20:23 docker-machine-prompt.bash
-rw-r--r--   1 root root  1525 июн 27 20:23 docker-machine-wrapper.bash
-rw-r--r--   1 root root   439 апр 26 12:43 git-prompt
```
To enable the docker-machine shell prompt, add

**PS1='[\u@\h \W$(__docker_machine_ps1)]\$ '**

to your PS1 setting in **~/.bashrc**

Далее попрактикуемся
```bash
$ docker run -it ubuntu:18.04 /bin/bash
root@015de5d533b6:/# cat /etc/os-release
NAME="Ubuntu"
VERSION="18.04.6 LTS (Bionic Beaver)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 18.04.6 LTS"
VERSION_ID="18.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=bionic
UBUNTU_CODENAME=bionic
root@015de5d533b6:/# echo 'Hello world!' > /tmp/file
root@015de5d533b6:/# cat /tmp/file
Hello world!
root@015de5d533b6:/# exit
```
Команда **run** создает и запускает контейнер из **image**. Если **docker engine** не нашел указанный **image** локально, то скачивает его с **Docker Hub**. И уж при втором запуске не будет скачивать.
```bash
$ sudo docker run -it ubuntu:18.04 /bin/bash
root@44848161a8bb:/# cat /tmp/file
cat: /tmp/file: No such file or directory
root@44848161a8bb:/# exit
exit
```
При закрытии запущенного контейнера все изменения и созданные файды тоже стираются. И при новом запуске контейнера создаются изначалный вид.
Если не указывать флаг **--rm** при запуске **docker run**, то после остановки контейнер вместе с содержимым остается на диске

**docker run** каждый раз запускает новый контейнер
Попробую найти ранее созданный контейнер в котором есть **/tmp/ﬁle** . Это должен быть предпоследний контейнер запущенный из образа **ubuntu:18.04**
```bash
$ docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.CreatedAt}}\t{{.Names}}"
CONTAINER ID   IMAGE          CREATED AT                      NAMES
44848161a8bb   ubuntu:18.04   2023-06-27 20:42:23 +0300 MSK   happy_liskov
015de5d533b6   ubuntu:18.04   2023-06-27 20:41:32 +0300 MSK   stoic_mendeleev
0406211abee7   hello-world    2023-06-26 20:50:42 +0300 MSK   stoic_liskov
```

### Docker start & attach

- **CONTAINER ID** у всех разный, поэтому можно указывать его при выборе контейнера
- **docker start** запускает остановленный(уже созданный) контейнер
- **docker attach** подсоединяет терминал к созданному контейнеру

```bash
$ sudo docker start 015
015
$ sudo docker attach 015
root@015de5d533b6:/#
```
```bash
root@015de5d533b6:/# cat /tmp/file
Hello world!
```
```bash
$ sudo docker ps
CONTAINER ID   IMAGE          COMMAND       CREATED          STATUS         PORTS     NAMES
015de5d533b6   ubuntu:18.04   "/bin/bash"   19 minutes ago   Up 2 seconds             stoic_mendeleev
```
### Docker run vs start

Коротко, при наличии опции **-i**
```bash
docker run = docker create + docker start + docker attach
```
- **docker create** используется, когда не нужно стартовать контейнер сразу
- в большинстве случаев используется **docker run**
- Через параметры передаются лимиты (cpu/mem/disk), ip, volumes
- -i – запускает контейнер в foreground режиме ( docker attach )
- -d – запускает контейнер в background режиме
- -t создает TTY
- **docker run -it ubuntu:18.04 bash**
- **docker run -dt nginx:latest**

### Docker exec

- Запускает новый процесс внутри контейнера
- Например, **bash** внутри контейнера с приложением
```bash
$ sudo docker ps -a
CONTAINER ID   IMAGE          COMMAND       CREATED          STATUS                      PORTS     NAMES
44848161a8bb   ubuntu:18.04   "/bin/bash"   27 minutes ago   Exited (1) 25 minutes ago             happy_liskov
015de5d533b6   ubuntu:18.04   "/bin/bash"   28 minutes ago   Up 9 minutes                          stoic_mendeleev
0406211abee7   hello-world    "/hello"      24 hours ago     Exited (0) 24 hours ago               stoic_liskov

$ sudo docker exec -it 015 bash
root@015de5d533b6:/# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0  18520  3156 pts/0    Ss+  18:00   0:00 /bin/bash
root          11  0.2  0.0  18520  3160 pts/1    Ss   18:10   0:00 bash
root          21  0.0  0.0  34416  2804 pts/1    R+   18:10   0:00 ps aux

root@015de5d533b6:/# ps axf
    PID TTY      STAT   TIME COMMAND
     11 pts/1    Ss     0:00 bash
     22 pts/1    R+     0:00  \_ ps axf
      1 pts/0    Ss+    0:00 /bin/bash

root@015de5d533b6:/# exit
exit
```
### Docker commit
- Создает **image** из контейнера
- Контейнер при этом остается запущенным

```bash
$ sudo docker start 015
$ sudo docker ps
CONTAINER ID   IMAGE          COMMAND       CREATED          STATUS          PORTS     NAMES
015de5d533b6   ubuntu:18.04   "/bin/bash"   34 minutes ago   Up 21 seconds             stoic_mendeleev

$ sudo docker images
REPOSITORY    TAG       IMAGE ID       CREATED       SIZE
ubuntu        18.04     f9a80a55f492   4 weeks ago   63.2MB
hello-world   latest    9c7a54a9a43c   7 weeks ago   13.3kB
```

Создаю **image** из запущенного контейнера
```bash
$ sudo docker commit 015 russo1982/ubuntu-tmp-file
sha256:9c764ec818184a63cdc198d4da43f71037f79a984e0f7eba466533f568aaed64

$ sudo docker images
REPOSITORY                  TAG       IMAGE ID       CREATED         SIZE
russo1982/ubuntu-tmp-file   latest    9c764ec81818   5 seconds ago   63.2MB
ubuntu                      18.04     f9a80a55f492   4 weeks ago     63.2MB
hello-world                 latest    9c7a54a9a43c   7 weeks ago     13.3kB
```

## Задание со *

- Сравнитт вывод двух следующих команд
```bash
$ docker inspect <u_container_id>
$ docker inspect <u_image_id>
```

Запускаю докер контейнер на основе созданного докер имеджа
```bash
$ sudo docker images
REPOSITORY                  TAG       IMAGE ID       CREATED        SIZE
russo1982/ubuntu-tmp-file   latest    9c764ec81818   20 hours ago   63.2MB
ubuntu                      18.04     f9a80a55f492   4 weeks ago    63.2MB
hello-world                 latest    9c7a54a9a43c   7 weeks ago    13.3kB

$ sudo docker run russo1982/ubuntu-tmp-file
$ sudo docker ps -a
CONTAINER ID   IMAGE                       COMMAND       CREATED         STATUS                     PORTS     NAMES
138fbc837b42   russo1982/ubuntu-tmp-file   "/bin/bash"   3 minutes ago   Exited (0) 3 minutes ago             mystifying_wright
0406211abee7   hello-world                 "/hello"      45 hours ago    Exited (0) 45 hours ago              stoic_liskov
```
И теперь можно начать сравнивать контейнер и имедж
```bash
$ sudo docker inspect 138f
$ sudo docker inspect russo1982/ubuntu-tmp-file
```
Буду изучать чем отличается контейнер от образа.

Отличичие первое в том, что в докер имедж содержится исходная информация о слоях и описание нужное для создание контейнера.
А уже в контейнере дополнительно описываются инфраструктурные элементы как сеть, volume, запущенные процесы, HostnamePath, Platform и др.

---

### Docker kill & stop

- kill сразу посылает SIGKILL
- stop посылает SIGTERM , и через 10 секунд (настраивается) посылает SIGKILL
- SIGTERM - сигнал остановки приложения
- SIGKILL - безусловное завершение процесса
- Подробнее про сигналы в Linux [https://ru.wikipedia.org/wiki/%D0%A1%D0%B8%D0%B3%D0%BD%D0%B0%D0%BB_(Unix)]

```bash
$ sudo docker ps -q # показывает id контейнера который запущен с опциями -it
3aea3ec2c4ce
$ sudo docker kill $(sudo docker ps -q)
3aea3ec2c4ce
```

### docker system df

- Отображает сколько дискового пространства занято образами, контейнерами и volume’ами
- Отображает сколько из них не используется и возможно удалить

### Docker rm & rmi

- rm удаляет контейнер, можно добавить флаг -f , чтобы удалялся работающий container (будет послан SIGKILL )
- rmi удаляет image, если от него не зависят запущенные контейнеры

```bash
$ docker rm $(docker ps -a -q) # удалит все незапущенные контейнеры
```
---

## Docker-контейнеры

Надо установить Yandex Cloud CLI

**docker-machine** - встроенный в докер инструмент для создания хостов и установки на них docker engine. Имеет поддержку облаков и систем виртуализации (Virtualbox, GCP и др.)

Вобщем задача стоит такая, что в инстансе в Yandex Cloud запускается докер. Соответственно этим докером можно будет управлять через **docker-machine**

Команда создания
- **docker-machine create <имя>**

Имен может быть много, переключение между ними через
 - **eval $(docker-machine env <имя>)**

 Переключение на локальный докер
 - **eval $(docker-machine env --unset)**

 Удаление
 - **docker-machine rm <имя>**

Повторю еще раз
- yc создаст инстанс из стандартного образа в image-family ubuntu-1804-lts
- **docker-machine** инициализирует на нём докер хост систему
- После запуска **eval $(docker-machine env <имя>)** все докер команды запускаемые в той же консоли работают с удаленным докер демоном в Yandex Cloud.

Начнём!!!

Создад Docker хост в Yandex Cloud и настрою локальное окружение на работу с ним
```bash
$ yc compute instance create \
  --name docker-host \
  --hostname russo-docker-host \
  --cores 2 \
  --core-fraction 5 \
  --preemptible \
  --zone "ru-central1-a" \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1804-lts,size=15 \
  --ssh-key ~/.ssh/appuser.pub
```
Инстанс в Yandex Cloud создан и теперь создаём докер демон в этом инстансе. Но сперва надо заметить что сразу указываем свойство **--engine-storage-driver overlay2**. Иначе будет ошибка:
```bash
Setting Docker configuration on the remote daemon...
Error creating machine: Error running provisioning: ssh command error:
command : sudo systemctl -f start docker
err     : exit status 1
output  : Job for docker.service failed because the control process exited with error code.
See "systemctl status docker.service" and "journalctl -xe" for details.
```
Причиной которого является:
```bash
dockerd[4651]: failed to start daemon: error initializing graphdriver: [graphdriver] ERROR: the aufs storage-driver has been deprecated and removed; visit https://docs.docker.com/go/storage-driver/ for more information: aufs
```
Вот и всё создаём докер демон в инстансе

```bash
$ docker-machine create \
  --driver generic \
  --engine-storage-driver overlay2 \
  --generic-ip-address=158.160.50.181 \
  --generic-ssh-user yc-user \
  --generic-ssh-key ~/.ssh/appuser \
  docker-host
```
Кстати, если замчаешься с ошибкой:
```bash
Docker machine "some machine" already exists
```
то просто сделай это:
```bash
$ rm -rv ~/.docker/machine/machines/*
```
Вот результат
```bash
Checking connection to Docker...
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env docker-host
```
После данной процедуру взял паузу и отключил инстанс в Yandex Cloud. А когда на следующий день запустил инстанс **docker-machine** не мог найти инстанс, так как у него IP уже был другой. Для решение этой проблемы надо поменять настройки в файлу **~/.docker/machine/machines/docker-host/config.json** и указать актуальный IP адрес.
После выдет следующая проблема:
```bash
$ docker-machine ls
NAME          ACTIVE   DRIVER    STATE     URL                          SWARM   DOCKER    ERRORS
docker-host   -        generic   Running   tcp://158.160.101.119:2376           Unknown   Unable to query docker version: Get https://158.160.101.119:2376/v1.15/version: x509: certificate is valid for 158.160.50.181, not 158.160.101.119
```
Для решения запускаю:
```bash
$ docker-machine provision docker-host
$ docker-machine ls
NAME          ACTIVE   DRIVER    STATE     URL                          SWARM   DOCKER    ERRORS
docker-host   -        generic   Running   tcp://158.160.101.119:2376           v24.0.2
```
Ну всё, дальше надо работать.
Теперь переключаюсь на работу с этим удалённым докер демоном
```bash
$ docker-machine env docker-host
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://158.160.101.119:2376"
export DOCKER_CERT_PATH="/home/russo/.docker/machine/machines/docker-host"
export DOCKER_MACHINE_NAME="docker-host"
# Run this command to configure your shell:
# eval $(docker-machine env docker-host)
```
```bash
eval $(docker-machine env docker-host)
```
И ради Бога не закрывай данную сесси в терминале, чтоб не потерять переменные среды **eval $(docker-machine env docker-host)** Также надо проверить докер образы в самом инстансе. Схожу туда по **ssh**
```bash
$ ssh yc-user@158.160.54.188

yc-user@docker-host:~$ sudo docker images -a
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
reddit       latest    48fdba02d556   2 minutes ago   690MB
```
Всё! Теперь при запуске докер команды изменения будут происходить в инстансе Yandex Cloud.
---

## Структура репозитория

Далее создам четыре файла в директории **docker-monolith** и вся работа происходит в этой директории
- Dockerfile - текстовое описание нашего образа
- mongod.conf - подготовленный конфиг для mongodb
- db_config - содержит переменную окружения со ссылкой на mongodb
- start.sh - скрипт запуска приложения

Создам **Dockerﬁle**
```bash
FROM ubuntu:18.04 # а основу беру дистрибутив Ubuntu версии 18.04

# для работы приложения нужны mongo и ruby
RUN apt-get update
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential git

# из-за bundler requires Ruby version >= 2.6.0. The current ruby version is 2.5.0
# надо указать версию. Иначе будет ошибка ERROR: failed to solve: process "/bin/sh -c gem install bundler" did not complete successfully
RUN gem install bundler -v 2.3.26

# скачиваю приложение в контейнер из git репо
RUN git clone -b monolith https://github.com/express42/reddit.git

# скопирую файлы конфигурации в создаваемый контейнер
COPY mongod.conf /etc/mongod.conf
COPY db_config /reddit/db_config
COPY start.sh /start.sh

# нужно установить зависимости приложения и произвести настройку
RUN cd /reddit && rm Gemfile.lock && bundle install
RUN chmod 0777 /start.sh

# добавляю команду для старт сервиса при запуске контейнера
CMD ["/start.sh"]
```

### Сборка образа

Попробую собрать свой образ

```bash
$ docker build -t reddit:latest . # Точка в конце обязательна, она указывает на путь до Docker-контекста, а флаг -t задает тег для собранного образа

# проверю список образов
$ docker images -a
REPOSITORY                  TAG       IMAGE ID       CREATED         SIZE
reddit                      latest    da99fafa4c65   3 minutes ago   679MB
russo1982/ubuntu-tmp-file   latest    9c764ec81818   2 days ago      63.2MB
ubuntu                      18.04     f9a80a55f492   4 weeks ago     63.2MB
hello-world                 latest    9c7a54a9a43c   8 weeks ago     13.3kB
```

### Запуск контейнера

Теперь можно запустить контейнер командой:
```bash
$ docker run --name reddit -d --network=host reddit:latest
193e7613a492db9d99774e593604c56324f0b0e74939717083faa1cbff04226e
```
Проверю результат:
```bash
$ docker ps
CONTAINER ID   IMAGE           COMMAND       CREATED         STATUS         PORTS     NAMES
b9d28d0fd762   reddit:latest   "/start.sh"   7 seconds ago   Up 5 seconds             reddit

$ docker-machine ls
NAME          ACTIVE   DRIVER    STATE     URL                          SWARM   DOCKER    ERRORS
docker-host   -        generic   Running   tcp://158.160.101.119:2376           v24.0.2
```
Состояние указано "рабочее". Открываю в браузере http://158.160.101.119:9292
