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
