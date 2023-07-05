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

Работает родимая!!!
