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
