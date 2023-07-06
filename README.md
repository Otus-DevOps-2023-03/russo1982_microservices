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
