# russo1982_microservices


## ДЗ №22 Введение в мониторинг. Системы мониторинга. (работа с веткой: monitoring-1)
---
### ЦЕЛЬ/План
- Prometheus: запуск, конфигурация, знакомство с Web UI
- Мониторинг состояния микросервисов
- Сбор метрик хоста с использованием экспортера
- Задания со *

### Подготовка окружения

Создаю Docker хост в Yandex Cloud и настрою локальное окружение на работу с ним. Решил для этого использовать уже подготовленный сценарий из прошлых ДЗ.
Буду создавать через Terraform. Использую файл **docker-monoloth/infra/main.tf**

После установка докера на инстансе
```
docker-machine create \
  --driver generic \
  --engine-storage-driver overlay2 \
  --generic-ip-address=158.160.44.44 \
  --generic-ssh-user ubuntu \
  --generic-ssh-key ~/.ssh/appuser \
  docker-host-0
```
### Запуск Prometheus

Систему мониторинга **Prometheus** буду запускать внутри Docker контейнера. Для начального знакомства воспользуюсь готовым образом с **DockerHub**.
```
$ docker run --rm -p 9090:9090 -d --name prometheus prom/prometheus

$ docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED          STATUS         PORTS                                       NAMES
91d7fba486bd   prom/prometheus   "/bin/prometheus --c…"   12 seconds ago   Up 6 seconds   0.0.0.0:9090->9090/tcp, :::9090->9090/tcp   prometheus
```
По умолчанию сервер слушает на порту 9090.

### Навести порядок в структуру директорий в докальном репо

Для перехода к следующему шагу приведу структуру каталогов в более четкий/удобный вид:

- Создам директорию **docker** в корне репозитория и перенесу в нее директорию **docker-monolith** и файлы **docker-compose.** и все **.env**
(.env должен быть в .gitignore), в репозиторий закоммичен **.env.example**, из которого создается **.env**

- Создам в корне репозитория директорию **monitoring**. В ней будет хранится **все**, что относится к мониторингу.

- Не забываю при этом про **.gitignore** и актуализирую записи при необходимости

*С этого момента сборка сервисов отделена от **docker-compose**, поэтому инструкции **build** можно удалить из **docker-compose.yml***

### Создание Docker образа


Познакомившись с веб интерфейсом Prometheus и его стандартной конфигурацией, соберу на основе готового образа с DockerHub свой Docker образ с конфигурацией для мониторинга микросервисов.

Надо создать директорию **monitoring/prometheus**. Затем в этой директории создать простой **Dockerﬁle**, который будет копировать файл конфигурации с
машины внутрь контейнера:
**monitoring/prometheus/Dockerfile**
```
FROM prom/prometheus:v2.1.0
ADD prometheus.yml /etc/prometheus/
```

Вся конфигурация **Prometheus**, в отличие от многих других систем мониторинга, происходит через файлы конфигурации и опции командной строки. Надо определить простой конфигурационный файл для собра метрик с микросервисов. В директории **monitoring/prometheus** создам файл **prometheus.yml** со следующим содержимым
```
---
global:
  scrape_interval: "5s" # С какой частотой собирать метрики

scrape_configs:
  - job_name: "prometheus"  # Джобы объединяют в группы endpoint-ы, выполняющие одинаковую функцию
    static_configs:
      - targets:
          - "localhost:9090"  # Адреса для сбора метрик (endpoints)

  - job_name: "ui"
    static_configs:
      - targets:
          - "ui:9292"

  - job_name: "comment"
    static_configs:
      - targets:
          - "comment:9292"
```
В директории **prometheus** собираю Docker образ
```
$ export USER_NAME=username  # USER_NAME - мой логин от DockerHub
$ docker build -t $USER_NAME/prometheus .
```
Результат из самого инстанса
```
ubuntu@docker-host-0:~$ sudo docker images
REPOSITORY                   TAG       IMAGE ID       CREATED       SIZE
prom/prometheus              latest    3b907f5313b7   2 weeks ago   245MB
russo1982docker/prometheus   latest    a1d41e762fb5   5 years ago   112MB
```

### Сборка images микросервисов

В коде микросервисов есть healthcheck-и для проверки работоспособности приложения. Сборку образов теперь необходимо производить при помощи скриптов **docker_build.sh**, которые есть в директории каждого сервиса. С его помощью добавлю информацию из Git в healthcheck.

Для этого перехожу в директорию **src/** где есть директории микросервисов
```
tree -d
.
├── comment
├── post-py
└── ui
```
Далее в каждом из директории запускаю следующие команды для сборки образа каждого микросервиса
```
/src/ui       $ bash docker_build.sh
/src/post-py  $ bash docker_build.sh
/src/comment  $ bash docker_build.sh
```
Результат из инстанса
```
ubuntu@docker-host-0:~$ sudo docker images
REPOSITORY                   TAG       IMAGE ID       CREATED         SIZE
russo1982docker/comment      latest    fa117dd5fd59   4 minutes ago   900MB
russo1982docker/post         latest    f59e63e7ee2d   5 minutes ago   61.4MB
russo1982docker/ui           latest    92c16d380c34   7 minutes ago   384MB
russo1982docker/prometheus   latest    a1d41e762fb5   5 years ago     112MB
prom/prometheus              latest    3b907f5313b7   2 weeks ago     245MB
```
Все нужные докер-образы созданы теперь осталось создать файл **docker/docker-compose.yml** где и укажу какие будут настройки для запуска каждого докер-образа, и определю правила взаимосвязи между ними.

Вот только нет еще докер-образа MongoDB на Яндекс инстансе. И его тоже создаю
```
docker pull mongo:3.2

ubuntu@docker-host-0:~$ sudo docker images
REPOSITORY                   TAG       IMAGE ID       CREATED          SIZE
russo1982docker/comment      latest    fa117dd5fd59   30 minutes ago   900MB
russo1982docker/post         latest    f59e63e7ee2d   31 minutes ago   61.4MB
russo1982docker/ui           latest    92c16d380c34   33 minutes ago   384MB
prom/prometheus              latest    3b907f5313b7   2 weeks ago      245MB
mongo                        3.2       fb885d89ea5c   4 years ago      300MB
russo1982docker/prometheus   latest    a1d41e762fb5   5 years ago      112MB

```

```
version: '3.3'
services:
  post_db:
    image: "mongo:${MONGO_VERSION}"
    volumes:
      - post_db:/data/db
    networks:
      - back_net

  ui:
    build: ./ui
    image: "${USERNAME}/ui:${TAG}"
    ports:
      - ${UI_PORT}
    networks:
      - front_net

  post:
    build: ./post-py
    image: "${USERNAME}/post:${TAG}"
    networks:
      - front_net
      - back_net

  comment:
    build: ./comment
    image: "${USERNAME}/comment:${TAG}"
    networks:
      - front_net
      - back_net

volumes:
  post_db:


networks:
#  reddit-network:

  back_net:
    name: Network for DB comment post
    driver: ${NETWORK_DRIVER}
    ipam:
      config:
        - subnet: ${BACK_SUBNET}
          gateway: ${BACK_GW}

  front_net:
    name: Network for UI comment post
    driver: ${NETWORK_DRIVER}
    ipam:
      config:
        - subnet: ${FRONT_SUBNET}
          gateway: ${FRONT_GW}
```

Поднимаю сервисы, определенные в **docker/docker-compose.yml**
```
docker-compose up -d
```

## Мониторинг состояния микросервисов
