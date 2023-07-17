# russo1982_microservices


## ДЗ №18 Docker: сети, docker-compose (работа с веткой: docker-4)
---
### ЦЕЛЬ
- Работа с сетями в Docker
- Использование docker-compose

### ПЛАН
- Разобраться с работой сети в Docker
   - none
   - host
   - bridge

### None network driver

Запускаю контейнер с использованием сетевого драйыера **none**. В качестве образа использую **joﬀotron/docker-net-tools** для экономии сил и времени,
т.к. в его состав уже входят необходимые утилиты для работы с сетью:
- пакеты
  - bind-tools,
  - net-tools и curl.
Контейнер запустится, выполнить команду **ifconfig** и будет удален (флаг --rm).
Запускаю следующую команду:
```bash
$ docker run -ti --rm --network none joffotron/docker-net-tools -c ifconfig
```
Тут запускается докер-контецнер на основа образа **joffotron/docker-net-tools** и сразу послу запуска контейнера следом срабатывает команда **iifconfig**
```bash
Unable to find image 'joffotron/docker-net-tools:latest' locally
latest: Pulling from joffotron/docker-net-tools
3690ec4760f9: Pull complete
0905b79e95dc: Pull complete
Digest: sha256:5752abdc4351a75e9daec681c1a6babfec03b317b273fc56f953592e6218d5b5
Status: Downloaded newer image for joffotron/docker-net-tools:latest
lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```
В результате видно, что из четевых интерфесов есть только **loopback** и сетевой стек самого контейнера работает (ping localhost), но без возможности контактировать с внешним миром. Значит, можно даже запускать сетевые сервисы внутри такого контейнера, но лишь для локальных экспериментов (тестирование, контейнеры для выполнения разовых задач и т.д.)

Теперь следющая команда
```
$ docker run -ti --rm --network host joffotron/docker-net-tools -c ifconfig
```
После этой команды создаётся контейнер с сетевым драйвером **host** что позволяет создать следующие сетевые интерфейсе на самом хочте, где работает сам докер
  - br-dd44e6c0aa78
  - docker0
  - docker0
  - docker0

Именнто такие же интерфейсы можно наблюдать при подключению к этому хосту
```
$ docker-machine ssh docker-host-0 ip add sh
```
Далее запускаю следующую команду три раза:
```
$ docker run --network host -d nginx
  Status: Downloaded newer image for nginx:latest
  1c8885becca16f3763b493021cbee1eb4c7af0ff9db535627169259f1f4521c4
  63002da70b54de77fe450ed183e993b91024f4fcdb8c2bbdb946c4056869b2a4
  293f27e6021e04d1848651cea67ee4bf91ef988e1c40da7399894ca6a127872d
```
Как видно каждый раз **ID** контейнера указан другой. И вот такой интересный результат:
```
$ docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS         PORTS     NAMES
1c8885becca1   nginx     "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes             jolly_pascal
```
```
$  docker ps -a
CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS                     PORTS     NAMES
293f27e6021e   nginx     "/docker-entrypoint.…"   2 minutes ago   Exited (1) 2 minutes ago             unruffled_wright
63002da70b54   nginx     "/docker-entrypoint.…"   2 minutes ago   Exited (1) 2 minutes ago             nervous_easley
1c8885becca1   nginx     "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes                         jolly_pascal
```
Как видно активным остаётся первый контейнер, а две следующие пытались запуститься, но что-то помешало им сработать.
```
ubuntu@docker-host-0:~$ ss -lntp
State              Recv-Q              Send-Q                              Local Address:Port                             Peer Address:Port
LISTEN             0                   128                                 127.0.0.53%lo:53                                    0.0.0.0:*
LISTEN             0                   128                                       0.0.0.0:22                                    0.0.0.0:*
LISTEN             0                   128                                       0.0.0.0:80                                    0.0.0.0:*
```

### NAMESPACE

Проверю как меняются **namespace** файле **/var/run/docker/netns/default** в Яндекс Инстансе. Для этого на **docker-host-0** машине выполните команду:
```
$ sudo ln -s /var/run/docker/netns /var/run/netns
```
Тут создаю симболик линк **/var/run/netns** который указывает на директорию **/var/run/docker/netns** тем самым можно просматривать существующие в данный
момент net-namespaces с помощью команды находясь в **docker-host-0**:
```
$ sudo ip netns
```
И теперь снова запускаю контейнеры с использованием сетевых драйверов **none** и **host** и проверю, как меняется список **namespace**-ов.

```
$ sudo ip netns
  5f2d6dc16177
  default
```
### Bridge network driver

```
$ docker network ls
  NETWORK ID     NAME             DRIVER    SCOPE
  27f20c3ecf96   bridge           bridge    local
  93b333d47893   host             host      local
  aee7cae3b2af   none             null      local
  dd44e6c0aa78   reddit-network   bridge    local
```
**bridge-сеть** уже была создана ранее и называется **reddit-network**

Все сервисы ссылаются друг на друга по dns-именам, прописанным в ENV-переменных (см Dockerfile). Поэтому указываю имена контейнерам или сетевых алиасов при старте как это было ранее
```
$ docker run -d --network=reddit-network --network-alias=post_db --network-alias=comment_db mongo:latest
$ docker run -d --network=reddit-network --network-alias=post russo1982docker/post:2.0
$ docker run -d --network=reddit-network --network-alias=comment russo1982docker/comment:2.0
$ docker run -d --network=reddit-network -p 9292:9292 russo1982docker/ui:2.0
```
И тут вроде всё должно работать, но проблема всё еще остаётся.

Попробую запустить проект в 2-х bridge сетях. Так , чтобы сервис ui не имел доступа к базе данных.

Сперва удалю активные контейнеры
```
$ docker kill $(docker ps -q)
$ docker rm $(docker ps -a -q)
```
Создаю docker-сети
```
$ docker network create back_net --subnet=10.0.2.0/24
$ docker network create front_net --subnet=10.0.1.0/24
$ docker network ls
NETWORK ID     NAME             DRIVER    SCOPE
08f0ed30c8d4   back_net         bridge    local
27f20c3ecf96   bridge           bridge    local
7cd9e104d5ea   front_net        bridge    local
93b333d47893   host             host      local
aee7cae3b2af   none             null      local
dd44e6c0aa78   reddit-network   bridge    local
```
Запускаю контейнеры:
```
$ docker run -d --network=back_net --name mongo_db --network-alias=post_db --network-alias=comment_db mongo:latest
```
```
$ docker run -d --network=back_net --name post russo1982docker/post:2.0
```
```
$ docker run -d --network=back_net --name comment russo1982docker/comment:2.0
```
```
$ docker run -d --network=front_net --name ui -p 9292:9292 russo1982docker/ui:2.0
```

Docker при инициализации контейнера может подключить к нему только одну сеть. При этом контейнеры из соседних сетей не будут доступны как в DNS, так и для взаимодействия по сети. Поэтому нужно поместить контейнеры **post** и **comment** в обе сети.

Дополнительные сети подключаются командой:
```
$ docker network connect front_net post
$ docker network connect front_net comment
```
---

## Docker-compose

  При работе с Docker-compose можно найти решения к следующим проблемам докер-контейнеров
  - Одно приложение состоит из множества контейнеров/сервисов
  - Один контейнер зависит от другого
  - Порядок запуска имеет значение
  - docker build/run/create … использовать эти команды долго и много
  - Отдельная утилита
  - Декларативное описание docker-инфраструктуры в YAML-формате
  - Управление многоконтейнерными приложениями

  То есть Docker-compose можно понимать как Ansible для работы с контейнерами.

  ### ПЛАН

  - Установить docker-compose на локальную машину
  - Собрать образы приложения reddit с помощью docker-compose
  - Запустить приложение reddit с помощью docker-compose

Установка docker-compose V2, потому что *From July 2023 Compose V1 stopped receiving updates.*
```
$ sudo apt-get update
$ sudo apt  install docker-compose
```

Далее в директории с проектом **reddit-microservices**, папка **src**, из предыдущего домашнего задания создаю файл **docker-compose.yml**
docker-compose поддерживает интерполяцию (подстановку) переменных окружения. Поэтому перед запуском необходимо экспортировать
значения данных переменных окружения. В данном случае это переменная **USERNAME**.
Останвлю и удалю контейнеры:
```
$ docker kill $(docker ps -q)
$ docker rm $(docker ps -a -q)
```
Указываю значение переменной и запускаю процесс сборки контейнеров по правилам указанным в файле **docker-compose.yml**
```
$ export USERNAME=russo1982docker
$ docker-compose up -d
$ docker-compose ps
Name                  Command             State                    Ports
----------------------------------------------------------------------------------------------
src_comment_1   puma                          Up
src_post_1      python3 post_app.py           Up
src_post_db_1   docker-entrypoint.sh mongod   Up      27017/tcp
src_ui_1        puma                          Up      0.0.0.0:9292->9292/tcp,:::9292->9292/tcp
```
И О ЧУДО!!! ПРОБЛЕМА, КОТОРАЯ ПРЕСЛЕДОВАЛА МЕНЯ С ПРОШЛОГО ДЗ СЕЙЧАС ИСЧЕЗЛА И БАЗА-ЖАННЫХ ДОСТУПНА В ПОЛНОЙ МЕРЕ.
