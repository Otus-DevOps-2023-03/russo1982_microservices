# russo1982_microservices


## ДЗ №17 Docker-образы Микросервисы (работа с веткой: docker-3)
---

### ЦЕЛИ
- Научиться описывать и собирать Docker-образы для сервисного приложения
- Научиться оптимизировать работу с Docker-образами
- Запуск и работа приложения на основе Docker-образов, оценка удобства запуска контейнеров при помощи **docker run**

**ПЛАН**
- Разбить наше приложение на несколько компонентов
- Запустить наше микросервисное приложение

Для начало работы создаём Яндекс инстанс на основе образа созданного с помощью Packer где уже установлен Докер. Чуть меняю терраформ файл **main.tf**
```bash
...
boot_disk {
    initialize_params {
      image_id = var.image_id # указан образ с установленным Докером
      size     = 15
    }
  }
...
resource "yandex_vpc_address" "static_ip" {
  name = "static white IP"
  external_ipv4_address {
    zone_id = var.zone
  }
}
...
```
После создания инстанса проверяю, есть ли там Докер
```bash
$ ssh ubuntu@<ip address>
ubuntu@russo-docker-host0:~$ systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2023-07-05 19:14:09 UTC; 1min 3s ago
```

Работает родимая!!! Также привязываю туда **docker-machine**
```bash
docker-machine create \
  --driver generic \
  --engine-storage-driver overlay2 \
  --generic-ip-address= < IP address > \
  --generic-ssh-user ubuntu \
  --generic-ssh-key ~/.ssh/appuser \
  docker-host-0
```
```bash
$ docker-machine env docker-host-0
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://< IP address >:2376"
export DOCKER_CERT_PATH="~/.docker/machine/machines/docker-host-0"
export DOCKER_MACHINE_NAME="docker-host-0"
# Run this command to configure your shell:
# eval $(docker-machine env docker-host-0)
```

Далее скачиваю каталог с готовыми микросервисами
```bash
$ wget https://github.com/express42/reddit/archive/microservices.zip
$ unzip microservices.zip
$ mv reddit-microservices src
```
Приложение состоит из трех компонентов:
- **post-py** - сервис отвечающий за написание постов
- **comment** - сервис отвечающий за написание комментариев
- **ui** - веб-интерфейс, работающий с другими сервисами
также требуется база данных **MongoDB**

Внутри директории каждого сервиса создаю свой **Dockerfile**
```bash
$ ls -l src

comment
post-py
ui
```

- Сервис **post-py**  **./post-py/Dockerfile**
- Сервис **comment**  **./comment/Dockerfile**
- Сервис **ui**       **./ui/Dockerfile**
---

## Сборка приложения

Надо скачать последний образ MongoDB:
```bash
$ docker pull mongo:latest # Напоминаю что в данный момент работаем с докером на Яндекс Инстансе
```
Результат на Яндекс Инстансе
```bash
ubuntu@docker-host-0:~$ sudo docker images -a
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
mongo        latest    1f3d6ec739d8   40 hours ago   654MB
```
---

Далее сборка образов с сервисами:
Сборка **post-py**
```bash
docker build -t russo1982docker/post:1.0 ./src/post-py
```
Результат на Яндекс Инстансе
```bash
ubuntu@docker-host-0:~$ sudo docker images -a
REPOSITORY             TAG       IMAGE ID       CREATED              SIZE
russo1982docker/post   1.0       8a5333f5fe6a   About a minute ago   62.8MB
mongo                  latest    1f3d6ec739d8   40 hours ago         654MB
```
---

Сборка **comment**
```bash
docker build -t russo1982docker/comment:1.0 ./src/comment
```
Результат на Яндекс Инстансе
```bash
ubuntu@docker-host-0:~$ sudo docker images -a
REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
russo1982docker/comment   1.0       f130a3202c94   14 seconds ago   1.01GB
russo1982docker/post      1.0       8a5333f5fe6a   19 minutes ago   62.8MB
mongo                     latest    1f3d6ec739d8   40 hours ago     654MB
```
---
Сборка **ui**
```bash
docker build -t russo1982docker/ui:1.0 ./src/ui
```
Результат на Яндекс Инстансе
```bash
ubuntu@docker-host-0:~$ sudo docker images -a
REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
russo1982docker/ui        1.0       b1876815cd24   10 seconds ago   1.01GB
russo1982docker/comment   1.0       f130a3202c94   5 minutes ago    1.01GB
russo1982docker/post      1.0       8a5333f5fe6a   24 minutes ago   62.8MB
mongo                     latest    1f3d6ec739d8   41 hours ago     654MB
```
---

## Запуск приложения

Создам специальную сеть для запуска приложения. Благодаря созданной сети приложение смогут "общаться"
В данный момент есть слеующие докер сети в Яндекс Инстансе
```bash
ubuntu@docker-host-0:~$ sudo docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
56da26a8a710   bridge    bridge    local
93b333d47893   host      host      local
aee7cae3b2af   none      null      local
```
Создаю новую сеть
```bash
$ docker network create reddit-network
```
Результат на Яндекс Инстансе
```bash
buntu@docker-host-0:~$ sudo docker network ls
NETWORK ID     NAME             DRIVER    SCOPE
56da26a8a710   bridge           bridge    local
93b333d47893   host             host      local
aee7cae3b2af   none             null      local
7a42a463d076   reddit-network   bridge    local
```
И теперь запускаю контейнеры с приложениями:
```bash
docker run --rm -d --network=reddit-network \ # название сети
--network-alias=post_db \ # имя докер-хоста в сети
--network-alias=comment_db mongo:latest # используемый докер-образ для запуска контейнера
```
```bash
docker run --rm -d --network=reddit-network \
--network-alias=post russo1982docker/post:1.0
```
```bash
docker run --rm -d --network=reddit-network \
--network-alias=comment russo1982docker/comment:1.0
```
```bash
docker run --rm -d --network=reddit-network \
-p 9292:9292 russo1982docker/ui:1.0
```

На этой стадии работает только создание новых постов, но нне возможно отобразить данные. Есть проблемы с Докерфайлами или файлами в папке **src**
---

## Задание со ⭐

Надло реализовать следующее:
- Запустите контейнеры с другими сетевыми алиасами
- Адреса для взаимодействия контейнеров задаются через ENV - переменные внутри Dockerfile 'ов
- При запуске контейнеров ( docker run ) задайте им переменные окружения соответствующие новым сетевым алиасам, не пересоздавая образ
- Проверьте работоспособность сервиса

Для этого остановил контейнеры и удалил их. Теперь запускаю контейнера с новыми сетевыми алиасами. Использую те же докер образы что ранее создавал

```bash
docker run --rm -d --network=reddit-network \
--network-alias=new_post_db \
--network-alias=new_comment_db mongo:latest
```
```bash
docker run --rm -d --network=reddit-network \
--network-alias=new_post russo1982docker/post:1.0
```
```bash
docker run --rm -d --network=reddit-network \
--network-alias=new_comment russo1982docker/comment:1.0
```
```bash
docker run --rm -d --network=reddit-network \
-p 9292:9292 russo1982docker/ui:1.0
```
И в Докерфайле надо поменять назмания переменных
**post-py/Dockerfile**
```bash
ENV POST_DATABASE_HOST new_post_db
```
**comment/Dockerfile**
```bash
ENV COMMENT_DATABASE_HOST new_comment_db
```
**ui/Dockerfile**
```bash
ENV POST_SERVICE_HOST new_post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST new_comment
ENV COMMENT_SERVICE_PORT 9292
```
---

## Образы приложения

Как ранее уже замечал докер-образы приложения занимают немало места! Поэтому, подумаю как можно упростить, облегчить размеры докер-образов.
Пересоберу докер-образ и теперь укажу **ui** **FROM  ubuntu:16.04**
```bash
FROM ubuntu:16.04
RUN apt-get update \
    && apt-get install -y ruby-full ruby-dev build-essential \
    && gem install bundler --no-ri --no-rdoc

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
```
Надо удалить имеющийся докер-образ **ui** и создать заного. И стоить отметить что сборка докер-образа началась с нуля. Все слои были пересозданы.

Результат:
```bash
$ docker images -a
REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
russo1982docker/ui        1.0       eaf64b2ffe5a   46 seconds ago   384MB
russo1982docker/comment   1.0       ecb7b3f5e977   27 hours ago     900MB
russo1982docker/post      1.0       136c8794e3a2   27 hours ago     61.4MB
mongo                     latest    1f3d6ec739d8   6 days ago       654MB
```
как видно размеры докер-образа уже легче.

Далее надо реализовать следующие шаги:
- Попробуйте собрать образ на основе Alpine Linux
- Придумайте еще способы уменьшить размер образа
- Можете реализовать как только для UI сервиса, так и для остальных ( post , comment )
- Все оптимизации проводите в Dockerfile сервиса. Дополнительные варианты решения уменьшения размера образов можете оформить в виде файла Dockerfile.<цифра> в папке сервиса

В каждой директории соответствущего докер-образа создал файл **Dockerfile.2** где описаны правила сборки докер-образа.
Запускаю сборку
```bash
$ docker build -f src/post-py/Dockerfile.2 -t russo1982docker/post:2.0 ./src/post-py
& docker build -f src/comment/Dockerfile.2 -t russo1982docker/comment:2.0 ./src/comment
& docker build -f src/ui/Dockerfile.2 -t russo1982docker/ui:2.0 ./src/ui
```
Результат:
```bash
$ docker images -a
REPOSITORY                TAG       IMAGE ID       CREATED        SIZE
russo1982docker/ui        2.0       bf4a8e54dcb5   27 hours ago   291MB
russo1982docker/comment   2.0       fb2e6e12a284   27 hours ago   288MB
russo1982docker/post      2.0       2e8e7692f195   27 hours ago   61.4MB
mongo                     latest    1f3d6ec739d8   7 days ago     654MB
```
И видно, что докер-образы стали легче вдвое.

Запускаю контейнеры:
```bash
$ docker run --rm -d --network=reddit-network \
> --network-alias=post_db \
> --network-alias=comment_db mongo:latest
```
```bash
$ docker run --rm -d --network=reddit-network \
--network-alias=post russo1982docker/post:2.0
```
```bash
$ docker run --rm -d --network=reddit-network \
--network-alias=comment russo1982docker/comment:2.0
```
```bash
$ docker run --rm -d --network=reddit-network \
-p 9292:9292 russo1982docker/ui:2.0
```
Все контейнеры запустились
```bash
$ docker ps
CONTAINER ID   IMAGE                         COMMAND                  CREATED              STATUS              PORTS                                       NAMES
fbaaf68fb2fc   russo1982docker/ui:2.0        "puma"                   30 seconds ago       Up 28 seconds       0.0.0.0:9292->9292/tcp, :::9292->9292/tcp   pedantic_bouman
da903bd9630a   russo1982docker/comment:2.0   "puma"                   About a minute ago   Up About a minute                                               compassionate_liskov
e727a9249cd2   russo1982docker/post:2.0      "python3 post_app.py"    About a minute ago   Up About a minute                                               trusting_burnell
9dfb75193001   mongo:latest                  "docker-entrypoint.s…"   2 minutes ago        Up 2 minutes        27017/tcp                                   jovial_lamarr
```

---

## Создание Docker volume. Перезапуск приложения с volume

Тут конечно большие сомнения у меня на счет правильной работы **Docker volume**, так как проблема отоброжения уже имеющихся записей в базе данных остаётся.
Но, буду пробовать. Создам **Docker volume**
```bash
$ docker volume create reddit_db
```
И подключу его к контейнеру с MongoDB
```bash
$ docker run -d --network=reddit-network --network-alias=post_db \
--network-alias=comment_db -v reddit_db:/data/db mongo:latest
```

НА ЭТОМ ВСЁ. НО, НЕ НРАВИТЬСЯ МНЕ РАБОТА, ТАК КАК НЕ РАБОТАЕТ **Can't show blog posts, some problems with the post service.**

ВСЁ!!!
